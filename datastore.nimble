mode = ScriptMode.Verbose

packageName   = "datastore"
version       = "0.0.1"
author        = "Status Research & Development GmbH"
description   = "Simple, unified API for multiple data stores"
license       = "Apache License 2.0 or MIT"

requires "nim >= 1.2.0",
         "questionable >= 0.10.3 & < 0.11.0",
         "sqlite3_abi",
         "stew",
         "unittest2",
         "upraises >= 0.1.0 & < 0.2.0"
