version 1.0

import "sample.wdl" as sampleWorkflow
import "structs.wdl" as structs
import "tasks/biopet/sampleconfig.wdl" as biopetSampleConfig
import "tasks/macs2.wdl" as macs2

workflow pipeline {
    input {
        Array[File] sampleConfigFiles
        String outputDir
        ChipSeqInput chipSeqInput
    }

    call biopetSampleConfig.SampleConfigCromwellArrays as configFile {
      input:
        inputFiles = sampleConfigFiles,
        outputPath = "samples.json"
    }

    Root config = read_json(configFile.outputFile)

    scatter (sample in config.samples) {
        call sampleWorkflow.Sample as sampleTasks {
            input:
                chipSeqInput = chipSeqInput,
                sample = sample,
                outputDir = outputDir + "/samples/" + sample.id
        }

        File bamFiles = sampleTasks.bamFile.file
        File indexFiles = sampleTasks.bamFile.index
    }

    call biopetSampleConfig.CaseControl as caseControl {
        input:
            inputFiles =  bamFiles,
            inputIndexFiles = indexFiles,
            sampleConfigs = sampleConfigFiles,
            outputPath = "control.json"
    }

    scatter (control in caseControl.caseControls) {
        call macs2.PeakCalling as peakcalling {
            input:
                inputBams = control.inputBam.file,
                inputBamsIndex = control.inputBam.index,
                controlBams = control.controlBam.file,
                controlBamsIndex = control.controlBam.index,
                outDir = outputDir + "/macs2",
                sampleName = control.inputName
        }
    }

    output {
        Array[File]+ peakFile = peakcalling.peakFile
    }
}
