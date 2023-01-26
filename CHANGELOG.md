Changelog
==========

<!--

Newest changes should be on top.

This document is user facing. Please word the changes in such a way
that users understand how the changes affect the new version.
-->

version 1.0.0-dev
---------------------------
+ Update tasks so latest macs2.wdl is included
+ Macs2 Peakcalling will also be called for samples without a control.
+ Add an option to exclude regions
+ Create a ChipSeq pipeline that aligns data using bwa-mem and uses macs2 for
  the peak calling.
