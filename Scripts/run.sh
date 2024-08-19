#!/bin/bash

qemu-system-x86_64 -kernel ../kernel/arch/x86_64/boot/bzImage -initrd ../Output/image.img -append "console=ttyS0" -nographic
