#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${1:-$(cd -- "${script_dir}/.." && pwd)}"

python3 - "${repo_root}" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1]).resolve()

expected = {
    ("main.tf", "this"): (),
    ("main.interfaces.tf", "lock"): (),
    ("main.interfaces.tf", "role_assignment"): (
        "properties.principalId",
        "properties.roleDefinitionId",
        "properties.principalType",
        "properties.description",
        "properties.condition",
        "properties.conditionVersion",
        "properties.delegatedManagedIdentityResourceId",
    ),
    ("main.interfaces.tf", "diagnostic_setting"): (),
    ("modules/authentication-setting/main.tf", "this"): (),
    ("modules/discovery-rule/main.tf", "this"): (),
    ("modules/entity/main.tf", "this"): (),
    ("modules/relationship/main.tf", "this"): (
        "properties.parentEntityName",
        "properties.childEntityName",
    ),
    ("modules/signal-definition/main.tf", "this"): (),
}


def tokenize(text, filename):
    tokens = []
    index = 0
    line = 1
    length = len(text)

    while index < length:
        character = text[index]

        if character.isspace():
            line += character == "\n"
            index += 1
            continue

        if character == "#" or text.startswith("//", index):
            newline = text.find("\n", index)
            index = length if newline == -1 else newline
            continue

        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            if end == -1:
                raise ValueError(f"{filename}:{line}: unterminated block comment")
            line += text.count("\n", index, end + 2)
            index = end + 2
            continue

        if text.startswith("<<", index):
            match = re.match(r"<<(-?)([A-Za-z_][A-Za-z0-9_-]*)[ \t]*\r?\n", text[index:])
            if match:
                indented = match.group(1) == "-"
                delimiter = match.group(2)
                start_line = line
                index += match.end()
                line += 1
                while index < length:
                    newline = text.find("\n", index)
                    end = length if newline == -1 else newline
                    candidate = text[index:end].rstrip("\r")
                    if (candidate.strip() if indented else candidate) == delimiter:
                        index = length if newline == -1 else newline + 1
                        line += newline != -1
                        tokens.append(("heredoc", "", start_line))
                        break
                    line += newline != -1
                    index = length if newline == -1 else newline + 1
                else:
                    raise ValueError(f"{filename}:{start_line}: unterminated heredoc")
                continue

        if character == '"':
            start_line = line
            index += 1
            value = []
            while index < length:
                character = text[index]
                if character == "\\":
                    if index + 1 >= length:
                        raise ValueError(f"{filename}:{start_line}: unterminated string")
                    value.append(text[index + 1])
                    index += 2
                    continue
                if character == '"':
                    index += 1
                    tokens.append(("string", "".join(value), start_line))
                    break
                if character == "\n":
                    raise ValueError(f"{filename}:{start_line}: newline in quoted string")
                value.append(character)
                index += 1
            else:
                raise ValueError(f"{filename}:{start_line}: unterminated string")
            continue

        if character in "{}[]=,":
            tokens.append(("symbol", character, line))
            index += 1
            continue

        if character.isalpha() or character == "_":
            end = index + 1
            while end < length and (text[end].isalnum() or text[end] in "_.-"):
                end += 1
            tokens.append(("identifier", text[index:end], line))
            index = end
            continue

        tokens.append(("other", character, line))
        index += 1

    return tokens


def is_token(tokens, index, kind, value):
    return index < len(tokens) and tokens[index][0] == kind and tokens[index][1] == value


def parse_resource_file(path):
    relative_path = path.relative_to(root).as_posix()
    tokens = tokenize(path.read_text(), relative_path)
    resources = []
    depth = 0
    index = 0

    while index < len(tokens):
        if (
            depth == 0
            and is_token(tokens, index, "identifier", "resource")
            and is_token(tokens, index + 1, "string", "azapi_resource")
            and index + 3 < len(tokens)
            and tokens[index + 2][0] == "string"
            and is_token(tokens, index + 3, "symbol", "{")
        ):
            resource_name = tokens[index + 2][1]
            resource_line = tokens[index][2]
            assignments = []
            block_depth = 1
            cursor = index + 4

            while cursor < len(tokens) and block_depth > 0:
                token = tokens[cursor]
                if token[0] == "symbol" and token[1] == "{":
                    block_depth += 1
                    cursor += 1
                    continue
                if token[0] == "symbol" and token[1] == "}":
                    block_depth -= 1
                    cursor += 1
                    continue
                if (
                    block_depth == 1
                    and token[0] == "identifier"
                    and token[1] == "replace_triggers_refs"
                    and is_token(tokens, cursor + 1, "symbol", "=")
                ):
                    assignment_line = token[2]
                    value_index = cursor + 2
                    if not is_token(tokens, value_index, "symbol", "["):
                        raise ValueError(
                            f"{relative_path}:{assignment_line}: replace_triggers_refs must be a literal string list"
                        )
                    values = []
                    value_index += 1
                    while value_index < len(tokens) and not is_token(tokens, value_index, "symbol", "]"):
                        value_token = tokens[value_index]
                        if value_token[0] == "string":
                            values.append(value_token[1])
                        elif not (value_token[0] == "symbol" and value_token[1] == ","):
                            raise ValueError(
                                f"{relative_path}:{assignment_line}: replace_triggers_refs must be a literal string list"
                            )
                        value_index += 1
                    if value_index >= len(tokens):
                        raise ValueError(
                            f"{relative_path}:{assignment_line}: unterminated replace_triggers_refs list"
                        )
                    assignments.append(tuple(values))
                    cursor = value_index + 1
                    continue
                cursor += 1

            if block_depth != 0:
                raise ValueError(f"{relative_path}:{resource_line}: unterminated azapi_resource block")

            resources.append((relative_path, resource_name, resource_line, assignments))
            index = cursor
            continue

        if tokens[index][0] == "symbol":
            if tokens[index][1] == "{":
                depth += 1
            elif tokens[index][1] == "}":
                depth -= 1
                if depth < 0:
                    raise ValueError(f"{relative_path}:{tokens[index][2]}: unmatched closing brace")
        index += 1

    if depth != 0:
        raise ValueError(f"{relative_path}: unmatched braces")

    return resources


files = sorted(root.glob("*.tf"))
modules_directory = root / "modules"
if modules_directory.is_dir():
    files.extend(sorted(modules_directory.glob("*/*.tf")))

errors = []
resources = []
try:
    for source_file in files:
        resources.extend(parse_resource_file(source_file))
except (OSError, ValueError) as error:
    errors.append(str(error))

actual = {}
for relative_path, resource_name, resource_line, assignments in resources:
    key = (relative_path, resource_name)
    actual.setdefault(key, []).append((resource_line, assignments))

if not resources:
    errors.append("no module-owned azapi_resource blocks found")

for key in sorted(actual):
    if key not in expected:
        errors.append(f"{key[0]}: azapi_resource.{key[1]} is not in the expected module-owned inventory")

for key, expected_paths in expected.items():
    records = actual.get(key, [])
    if len(records) != 1:
        errors.append(
            f"{key[0]}: azapi_resource.{key[1]} occurs {len(records)} times; expected exactly 1"
        )
        continue

    line, assignments = records[0]
    if len(assignments) != 1:
        errors.append(
            f"{key[0]}:{line}: azapi_resource.{key[1]} has {len(assignments)} "
            "replace_triggers_refs assignments; expected exactly 1"
        )
        continue

    actual_paths = assignments[0]
    if len(actual_paths) != len(set(actual_paths)):
        errors.append(
            f"{key[0]}:{line}: azapi_resource.{key[1]} contains duplicate replacement paths"
        )
        continue

    if set(actual_paths) != set(expected_paths):
        errors.append(
            f"{key[0]}:{line}: azapi_resource.{key[1]} replacement paths "
            f"{sorted(actual_paths)!r}; expected {sorted(expected_paths)!r}"
        )

assignment_count = sum(
    len(assignments)
    for _, _, _, assignments in resources
)

for error in errors:
    print(error, file=sys.stderr)

print(
    f"module-owned azapi_resource blocks: {len(resources)}; "
    f"replace_triggers_refs assignments: {assignment_count}; "
    "immutable path sets: verified" if not errors else "immutable path sets: failed"
)

sys.exit(1 if errors else 0)
PY
