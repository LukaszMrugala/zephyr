import lxml.etree as ET

run1 = ET.parse('node1-junit1.xml')
run2 = ET.parse('node1-junit2.xml')
run3 = ET.parse('node1-junit3.xml')

failedCount=int(run1.xpath('//testsuite/@failures')[0])
print failedCount

#loop over any failure tags
for fail in run1.xpath(".//failure"):
	#get failed testcase info
	failedClass = fail.getparent().get('classname')
	failedTest = fail.getparent().get('name')

	print failedClass, "-", failedTest, " FAILED in run1..."

	#check subsequent runs for testcases with the same attributes
	match="//testcase[@classname=\'" + failedClass + "\' and @name=\'" + failedTest + "\']"
	#why bother recurse when haz baschetti? todo:
	for tc in run2.xpath(match):
		if tc.findall('failure'):
			print "... and in run2"
			for ct in run3.xpath(match):
				if ct.findall('failure'):
					print "... and in run3"
				else:
					print "PASSED in run3"
					#remove failure tag from original file, leaving run2 untouched
					fail.getparent().remove(fail)
					failedCount = failedCount - 1
		else:
			print "PASSED in run2"
			fail.getparent().remove(fail)
			failedCount = failedCount - 1

print str(failedCount)

for aaa in run1.xpath('//testsuite'):
	aaa.attrib['failures']=str(failedCount)

print run1.xpath('//testsuite/@failures')[0]

run1.write('junit.xml')
