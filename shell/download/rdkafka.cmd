set rdkafkaOutputFile=%tmp%\rdkafka.zip

copy %mainPath%\extensions\rdkafka\%minorVersion%.zip %rdkafkaOutputFile%

call %mainPath%\7zip\7za e "%rdkafkaOutputFile%" -o"%tmp%\rdkafka" -y

move /y %tmp%\rdkafka\php_rdkafka.dll %phpPath%\ext\php_rdkafka.dll
move /y "%tmp%\rdkafka\librdkafka.dll" "%phpPath%\librdkafka.dll"
move /y "%tmp%\rdkafka\librdkafka++.dll" "%phpPath%\librdkafka++.dll"

move /y %tmp%\rdkafka\* %phpPath%
