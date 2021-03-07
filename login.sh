#!/bin/sh

ssh -o StrictHostKeyChecking=no ubuntu@`terraform output -raw master_ip`