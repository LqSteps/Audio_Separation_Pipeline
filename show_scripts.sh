#!/usr/bin/env bash

mapfile -d "" files < <(
	find -type f \
		\( -iname "*.sh" -o -path "*/config/*" \) \
		-not -path "*/.venv/*" \
	-print0
)

for i in "${files[@]}"; do
	batcat -P "$i"
done
