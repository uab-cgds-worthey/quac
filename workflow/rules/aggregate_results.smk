rule multiqc_final_pass:
    input:
        TARGETS_SOMALIER,
        TARGETS_COVERAGE,
        TARGETS_CONTAMINATION,
        # OUT_DIR / "somalier" / "relatedness" / "somalier.html",
        # OUT_DIR / "somalier" / "ancestry" / "somalier.somalier-ancestry.html",
        # OUT_DIR / "indexcov" / "index.html",
        # OUT_DIR / "covviz/" / "covviz_report.html",
        # OUT_DIR / "mosdepth" / "mosdepth.html",
        expand(str(OUT_DIR / "verifyBamID" / "{sample}.Ancestry"),
            sample=SAMPLES)
    output:
        OUT_DIR / "multiqc/multiqc_report.html"
    message:
        "Aggregates QC results using multiqc."
    wrapper:
        "0.64.0/bio/multiqc"
