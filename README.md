# Unikernel - Proof of Concept

## What is a Unikernel?

A Unikernel is a specialised image that contains only the parts of the operating system and libraries needed to run a specific application. Unlike traditional operating systems, which are general, they support a wide range of functionalities. Unikernels are highly minimalist, focused on providing only the essentials for a single purpose, which makes them lighter and more secure.

## Motivation

Based on the Unikernel concept and what currently exists, it was decided to use the Linux kernel to turn it into a Unikernel.

This project was born from an idea explored in the context of a Master's thesis.

## Installation Guide

Follow the steps below to configure and run the project:

### Requirements
- Install the necessary development tools and libraries:
```bash
sudo apt-get update
sudo apt install flex
sudo apt install bison
sudo apt install libelf-dev
sudo apt install libssl-dev
sudo apt install qemu
```

#### Clone the project repository
```bash
git clone https://github.com/ItzPires/Unikernel---Proof-of-Concept.git
cd Unikernel---Proof-of-Concept
git submodule update --init --recursive
```

#### Compilation
-  To compile the Unikernel, run the following command:
```bash
./Scripts/build.sh <path_to_binary> [additional_parameters]
```

#### Execution
- To run the Unikernel in QEMU:
```bash
./Scripts/run.sh -t qemu
```
- To run the Unikernel in VMWare:
```bash
./Scripts/run.sh -t vmware
```
