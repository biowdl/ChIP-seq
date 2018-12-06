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
        Int MAPQthreshold = 30
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
                outputDir = outputDir + "/samples/" + sample.id,
                MAPQthreshold = MAPQthreshold
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

    scatter (control in caseControl.caseControls.caseControls) {
        call macs2.PeakCalling as peakcalling {
            input:
                inputBams = [control.inputFile.file],
                inputBamsIndex = [control.inputFile.index],
                controlBams = [control.controlFile.file],
                controlBamsIndex = [control.controlFile.index],
                outDir = outputDir + "/macs2",
                sampleName = control.inputName
        }
    }

    output {
        Array[File]+ peakFile = peakcalling.peakFile
    }
}
