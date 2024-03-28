#!/bin/sh

depmod -a

modprobe -r nouveau
modprobe nvidia
modprobe nvidia-uvm

nvidia-mkdevs
