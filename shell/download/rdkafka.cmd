set rdkafkaOutputFile=%tmp%\rdkafka.zip

copy %mainPath%\extensions\rdkafka\%minorVersion%.zip %rdkafkaOutputFile%

call %mainPath%\7zip\7za e "%rdkafkaOutputFile%" -o"%tmp%\rdkafka" -y

move /y %tmp%\rdkafka\php_rdkafka.dll %phpPath%\ext\php_rdkafka.dll
move /y "%tmp%\rdkafka\libcrypto-3-x64.dll" "%phpPath%\libcrypto-3-x64.dll"
move /y "%tmp%\rdkafka\libcurl.dll" "%phpPath%\libcurl.dll"
move /y "%tmp%\rdkafka\librdkafka.dll" "%phpPath%\librdkafka.dll"
move /y "%tmp%\rdkafka\librdkafkacpp.dll" "%phpPath%\librdkafkacpp.dll"
move /y "%tmp%\rdkafka\libssl-3-x64.dll" "%phpPath%\libssl-3-x64.dll"
move /y "%tmp%\rdkafka\msvcp140.dll" "%phpPath%\msvcp140.dll"
move /y "%tmp%\rdkafka\vcruntime140.dll" "%phpPath%\vcruntime140.dll"
move /y "%tmp%\rdkafka\zlib1.dll" "%phpPath%\zlib1.dll"
move /y "%tmp%\rdkafka\zstd.dll" "%phpPath%\zstd.dll"

move /y %tmp%\rdkafka\* %phpPath%
