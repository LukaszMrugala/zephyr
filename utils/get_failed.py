import os
import os.path
import sys
import optparse
import glob
import git
from lxml import etree
from utils import split_thing, rejoin_thing, get_active_branch

# Goes to the sanity-out dir, gets the respective xml result files (based on which branch we are on) and looks for failed test cases.
# Works for v1.14-branch-intel and master-intel branches.
# Currently ONLY looks for failed tests that remain after the last sanitycheck run. It does not look for skipped tests, etc
# It outputs the name of the test cases and the failure type.
#
#####################################################################################################################################

def sc_status(fname, status):
    with open(fname, 'w') as status_file:
        status_file.write(status)
    status_file.close()

def find_results(sanity_out, branch_name):

    # Go to the sanity-out dir and get all the right .xml files for the branch we are on
    os.chdir(sanity_out)

    if branch_name == "v1.14-branch-intel":
        xmlflavor = "node"
    elif branch_name == "master-intel":
        xmlflavor = "sanitycheck.xml"
    else:
       print("Not on an expected branch (v1.14-branch-intel or master-intel). Manual intervention required.")
       sys.exit(1)

    BLOB = glob.glob("*.xml")
    filelist = []

    # Now look for right xml files, and keep only what we want.
    for thing in BLOB:
        if (thing.find(xmlflavor) != -1):
            filelist.append(thing)

    return filelist


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
                    nuke_path = split_thing(classname, "sanity-out/")
                    if len(nuke_path) == 2:
                        classname = nuke_path[1]
                    test_chunks = split_thing(subchild.get("name"), " ")
                    test_name = test_chunks[0]
                    fail_type = grandchild.get("type")
                    dict_thing = {'classname': classname, 'test_name': test_name, 'Failed:': fail_type}
                    FAILED_TESTS.append(dict_thing)

    return FAILED_TESTS


if __name__ == "__main__":

    #os.system("clear")

    print()

    if len(sys.argv) != 2:
        print("USAGE: {0} <path_to_test_results_xml>".format(__file__))
        print("i.e. python3 get_failed.py /srv/build/zephyrproject/zephyr/sanity-out v1.14-branch-intel")
        sys.exit(1)

    SANITY_OUT = sys.argv[1]

    # What branch are we on?
    branch = get_active_branch(SANITY_OUT)
    print("Branch:", branch)

    # Get the list of testresult files
    result_files = find_results(SANITY_OUT, branch)

    print("Result Files:", result_files)
    print()

    # If there are no sanitycheck result files something went terribly sideways. Bail out.
    if not result_files:
        print ("Can't find any sanitycheck result files. Manual intervention required.")
        sys.exit(1)

    # Rip through the list and print out the failed tests
    failures = "FALSE"
    for results in result_files:
        failures = get_failed(results, failures)

    if failures:
       print("FAILED TESTS:")

       for testcase in failures:
           for thing in ['classname', 'test_name', 'Failed:']:
               print(testcase[thing], end =" ")
           print()
       print()
       print("Sanity Check is NOT CLEAN")
       sc_status("sc_status", "FAILED\n")
       sys.exit(1)
    else:
       print()
       print("Sanity Check is CLEAN.")
       sc_status("sc_status", "CLEAN\n")

    sys.exit(0)
