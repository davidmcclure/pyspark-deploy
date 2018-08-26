#!/bin/sh

MASTER_IP=$(head -n 1 terraform/.master-ip)
ssh ubuntu@$MASTER_IP
