# Unikernel - Proof of Concept

## What is a Unikernel?

A Unikernel is a specialised image that contains only the parts of the operating system and libraries needed to run a specific application. Unlike traditional operating systems, which are general, they support a wide range of functionalities. Unikernels are highly minimalist, focused on providing only the essentials for a single purpose, which makes them lighter and more secure.

## Motivation

Based on the Unikernel concept and what currently exists, it was decided to use the Linux kernel to turn it into a Unikernel.

This project was born from an idea explored in the context of a Master's thesis.

## Supported Execution Environments
  
| Environment | :heavy_check_mark: / :x:|
|--|--|
|QEMU| :heavy_check_mark: |
|VMware | :heavy_check_mark: |
|VMware ESXi | :heavy_check_mark: |

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
- To run the Unikernel in VMware:
```bash
./Scripts/run.sh -t vmware
```

This command will generate a file called disk.vmdk in the Output folder. To run the kernel in VMware, you must create a virtual machine in VMware, and during creation, you must select you will install the operating system later. In the disk creation menu, you should select, "Use an existing disk", and select the disk.vmdk file. The virtual machine is ready to be started.

- To run the Unikernel in VMware ESXi:

You must follow all the creation steps in VMware and then export the virtual machine in OVF. With these export files, you can create a virtual machine in VMware ESXi.
