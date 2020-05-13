import os
import os.path
import sys
import optparse
import glob
from lxml import etree
from utils import split_thing, rejoin_thing

# Go to the sanity-out dir and see if there are xml files in format of node<x>-junit<y>.xml. i.e. node1-junit3.xml
# This only checkes the toplevel of sanity-out directory, which works for v1.14-branch-intel.
# If we are on master or master-intel, there will be multiple files and they will not likely land in the toplevel sanity-out dir.
#    They will likely be under platform/arch subdirs. We'll deal with that later. For now, just looking for one node-whatever.xml files
#    in the toplevel of zephyr/sanity-out.
# Later we will recurse through platform subdirectories to get all the results files.


def find_results(sanity_out):

    # Go to the sanity-out dir and get all the .xml files (does not go into subdirs)
    os.chdir(sanity_out)
    BLOB = glob.glob("*.xml")

    # Now look for "node", and ditch everything that does not match.
    for thing in BLOB:
        foo = thing.find("node")
        if foo == -1:
            BLOB.remove(thing)

    return BLOB

def get_failed(results, failed):

    FAILED_TESTS = []

    with open(results) as testresults:
        tests = testresults.read()

    root = etree.fromstring(tests)

    for elem in root.getchildren():
        for subchild in elem.getchildren():
            attributes = subchild.attrib

            for grandchild in subchild.getchildren():
                if grandchild.tag == "failure":
                    class_chunks = split_thing(subchild.get("classname"), ":")
                    classname = class_chunks[0]
                    test_chunks = split_thing(subchild.get("name"), " ")
                    test_name = test_chunks[0]
                    fail_type = grandchild.get("type")
                    dict_thing = {'classname': classname, 'test_name': test_name, 'fail_type': fail_type}
                    FAILED_TESTS.append(dict_thing)

    return FAILED_TESTS

if __name__ == "__main__":

    #os.system("clear")

    print()

    if len(sys.argv) != 2:
        print("USAGE: {0} <path_to_test_results_xml>".format(__file__))
        print("i.e. python3 get_failed.py /srv/build/zephyrproject/zephyr/sanity-out")
        sys.exit(1)

    SANITY_OUT = sys.argv[1]
    if not os.path.exists(SANITY_OUT):
        print(SANITY_OUT + " directory does not appear to exist!")
        sys.exit(1)

    # Get the list of testresult files
    result_blob = find_results(SANITY_OUT)

    # Now we rip through the list and print out the failed tests
    failures = "FALSE"
    for results in result_blob:
        failures = get_failed(results, failures)

    if failures:
        print("FAILED TESTS:")

        for testcase in failures:
            for thing in ['classname', 'test_name', 'fail_type']:
                print(thing, testcase[thing], end =" ")
            print()
        sys.exit(1)
    else:
        print("Sanity Check is CLEAN.")
        sys.exit(0)

