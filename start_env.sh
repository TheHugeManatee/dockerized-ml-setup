#!/bin/bash
docker run --gpus all -it --rm -v /home/jakob/DVRNN:/src -v /home/jakob/data:/data nvcr.io/nvidia/pytorch:19.12-py3
