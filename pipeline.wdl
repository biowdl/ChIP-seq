version 1.0

import "sample.wdl" as sampleWorkflow
import "structs.wdl" as structs
import "tasks/biopet.wdl" as biopet

workflow pipeline {
    input {
        Array[File] sampleConfigFiles
        String outputDir
        File refFasta
        File refDict
        File refFastaIndex
    }

    call biopet.SampleConfigCromwellArrays as configFile {
      input:
        inputFiles = sampleConfigFiles,
        outputPath = "samples.json"
    }

    Root config = read_json(configFile.outputFile)

    scatter (sample in config.samples) {
        call sampleWorkflow.sample as sampleTasks {
            input:
                sample = sample,
                outputDir = outputDir + "/samples/" + sample.id
        }
    }

    output {

    }
}