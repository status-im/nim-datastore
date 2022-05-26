import pkg/questionable
import pkg/questionable/results
from pkg/stew/results as stewResults import get, isErr, isOk
import pkg/unittest2

import ../datastore/filesystem_datastore

suite "FileSystemDatastore":
    test "first light":

        check:
          1 == 1
