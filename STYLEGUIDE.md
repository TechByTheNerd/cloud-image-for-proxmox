# Bash Script Style Guide

This style guide aims to provide guidelines for writing clear and efficient scripts for our project. Following these conventions ensures that our code is not only functional but also consistent and maintainable.

## General Practices

1. **Use Clear and Descriptive Names**: Variables, functions, and filenames should have descriptive and meaningful names that reflect their purpose in the script.

2. **Indentation and Spacing**: Use consistent indentation (e.g., 2 or 4 spaces) to improve the readability of your code. Avoid excessive blank lines except to denote logical separations of code blocks.

3. **Commenting**: Comment your code adequately to explain "why" something is done, not "what" is done, which should be evident from the code itself.

4. **Idempotency**: Whenever possible, make the code [idempotent](https://en.wikipedia.org/wiki/Idempotence). In other words, the script should be able to be run many times, and it will not result in destruction. For example: upon first run the item is created. Upon second run it's verified that the item exists so that a second item isn't created.

## Error Checking

Always check the exit status of commands and handle errors appropriately. This is crucial for scripts that perform critical operations such as file manipulation, network operations, or system configuration. Use conditional statements to control the flow based on the success or failure of commands.

### Example

```bash
if [[ $(whoami) != "root" ]]; then
    echo -e "ERROR: This utility must be run as root (or sudo)."
    exit -1
fi
```

## Output and Logging

Use colored output to enhance readability of script logs. This helps in quickly identifying the status of operations (success, error, warning, etc.).

### Colors

Define color codes at the beginning of your scripts. Use these codes to maintain consistency across all scripts.

```bash
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
NC='\033[0m' # No Color
```

### Using Colored Prefixes

Employ colored prefixes to differentiate between types of messages:

- `[+]` for success
- `[-]` for errors
- `[?]` for warnings
- `[*]` for general information

#### Function Example

```bash
function setStatus() {
    description=$1
    severity=$2

    case "$severity" in
        s)
            echo -e "[${Green}+${NC}] ${Green}${description}${NC}"
        ;;
        f)
            echo -e "[${Red}-${NC}] ${Red}${description}${NC}"
        ;;
        q)
            echo -e "[${Yellow}?${NC}] ${Yellow}${description}${NC}"
        ;;
        *)
            echo -e "[${NC}*${NC}] ${description}${NC}"
        ;;
    esac
}
```

## Summary

Adhering to these style guidelines will help maintain the quality and reliability of our project's scripts. Consistent formatting, comprehensive error handling, and clear output logging are keys to developing robust and user-friendly scripts.
