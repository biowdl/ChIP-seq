import "sample.wdl" as sampleWorkflow
import "tasks/biopet.wdl" as biopet
import "tasks/macs2.wdl" as macs2

workflow pipeline {
    Array[File] sampleConfigFiles
    String outputDir
    File refFasta
    File refDict
    File refFastaIndex

    #  Reading the samples from the sample config files
    call biopet.SampleConfig as samplesConfigs {
        input:
            inputFiles = sampleConfigFiles,
            keyFilePath = outputDir + "/config.keys"
    }

    # Running sample subworkflow
    scatter (sm in read_lines(samplesConfigs.keysFile)) {
        call sampleWorkflow.sample as sample {
            input:
                outputDir = outputDir + "/samples/" + sm,
                sampleConfigs = sampleConfigFiles,
                sampleId = sm,
                refFasta = refFasta,
                refDict = refDict,
                refFastaIndex = refFastaIndex
        }
    }

    output {
        Array[String] samples = read_lines(samplesConfigs.keysFile)
    }
}