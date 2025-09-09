#!/usr/bin/env python3
import argparse
import vfio_prepare as prep

if __name__ == '__main__':
    #parser = argparse.ArgumentParser("simple_example")
    #parser.add_argument("file", help="File name", type=str)
    #args = parser.parse_args()
    prep.vfio_prepare("batocera")
