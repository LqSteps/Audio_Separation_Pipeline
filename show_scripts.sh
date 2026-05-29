#!/usr/bin/env bash

mapfile -d "" files < <(
	find -type f \
	-iname "*.sh" \
	-print0
)

for i in "${files[@]}"; do
	batcat -P "$i"
done
