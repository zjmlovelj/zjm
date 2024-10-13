
""" Log Formatting
<TIMESTAMP><TEST_START_INDENTATION>testname<TEST_NAME_CONNECTOR>subtestname<TEST_NAME_CONNECTOR>subsubtestname
<TIMESTAMP><RECORD_INDENTATION><RECORD_PREFIX>...<RECORD_SUFFIX>
<TIMESTAMP><FIXTURE_CMD_INDENTATION><FIXTURE_CMD_PREFIX>...<FIXTURE_CMD_SUFFIX>
<TIMESTAMP><FIXTURE_RESP_INDENTATION><FIXTURE_RESP_PREFIX>...<FIXTURE_RESP_SUFFIX>
<TIMESTAMP><DUT_CMD_INDENTATION><DUT_CMD_PREFIX>...<DUT_CMD_SUFFIX>
<TIMESTAMP><DUT_RESP_INDENTATION><DUT_RESP_PREFIX>...<DUT_RESP_SUFFIX>
<TIMESTAMP><FLOW_DEBUG_INDENTATION><FLOW_DEBUG_PREFIX>...<FLOW_DEBUG_SUFFIX>
<TEST_SEPARATOR>


Example with default setting:


"""
# Content Prefix/Suffix
TEST_NAME_PREFIX = "\n==Test: "
TEST_RESULT_PREFIX = "   "
RECORD_PREFIX = ""
FIXTURE_CMD_PREFIX = "[rpc_client]"
FIXTURE_RESP_PREFIX = "[result]"
DUT_CMD_PREFIX = "cmd-send:"
DUT_RESP_PREFIX = ""
FLOW_DEBUG_PREFIX = ""

TEST_NAME_SUFFIX = ""
RECORD_SUFFIX = ""
FIXTURE_CMD_SUFFIX = ""
FIXTURE_RESP_SUFFIX = ""
DUT_CMD_SUFFIX = ""
DUT_RESP_SUFFIX = ""
FLOW_DEBUG_SUFFIX = ""

TEST_SEPARATOR = "\n\n"

# Data Format
TIMESTAMP = "%Y/%m/%d %H:%M:%S.%f"
SUBTEST_NAME_CONNECTOR = "\n==SubTest: ".format("")
SUBSUBTEST_NAME_CONNECTOR = "\n==SubSubTest: ".format("")

# Content Indentation
TEST_START_INDENTATION = 2
TEST_RESULT_INDENTATION = 2
RECORD_INDENTATION = 2
FIXTURE_CMD_INDENTATION = 2
FIXTURE_RESP_INDENTATION = 2
DUT_CMD_INDENTATION = 2
DUT_RESP_INDENTATION = 2
FLOW_DEBUG_INDENTATION = 2

PREFIX_LEN = 0