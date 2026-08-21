#!/bin/bash

case "$1" in
    1)
        echo "Иванов Иван Иванович"
        ;;
    2)
        date '+%Y-%m-%d %H:%M:%S'
        ;;
    *)
        echo "Invalid argument. Use 1 for name or 2 for date."
        ;;
esac
