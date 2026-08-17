# NormaBRAIN Fork Project Plan

*From reproducible neuroimaging pipeline to inspectable computational reality*

Version 0.5 | 2026-08-17 | natosit-dev/normabrain_fk

# Prompt History

Relevant user prompts, preserved in chronological order. This is working provenance: it records how the project actually emerged instead of laundering the process into a fake retrospective plan.

**2026-08-16 —** My good friend Ryn is a neurobiologist, starting to try ML. Take a look at his repo, looks like some sort of DICOM processor? Lol using Bash was... A choice 😅

https://github.com/rf2485/normabrain/tree/main

**2026-08-16 —** Yeah, I mean I would've just stood up a Streamlit app as a control surface, persisted any data in duckdb not yaml. Conda is a good choice. Never heard of Singularity/apptainer or BIDS. But I want to fork this. I wanna fork out hard 😏

**2026-08-16 —** Can you fork it to my GitHub?

**2026-08-16 —** Just manually added the fork

**2026-08-16 —** First step- get it running locally

**2026-08-16 —** Ok, first I need to install WSL, thought I had it on this machine but I don't see it

**2026-08-16 —** Ok nvm I already had it installed XD I also have conda and git. What's next?

**2026-08-16 —** Let's see our decision log so far

**2026-08-16 —** Let's create an initial project plan for this in Nat style language with fancy style words when appropriate. Outline the purpose of normabrain, similarities to simulacra and recent experiments, key parts of the existing pipeline, and how we're going to poke around and clean some stuff up. We'll use existing medilacra pieces where appropriate- we solve problems once. Print it all to doc

**2026-08-17 —** Let's add prompt history at the top and a bit more info about MediLacra. Update the doc and increase the version.

**2026-08-17 —** Ok, let's jump back to establishing the baseline. This is where we left off

**2026-08-17 —** Where do I find the input? conda fix looks good

**2026-08-17 —** Ask is out to Ryn, but let's find a random public Siemens DICOM while we wait, see what happens

**2026-08-17 —** Yeah, the .dcm files are there. Here's the output

**2026-08-17 —** Looks good? Let's pause and update the decision log for the documentation along with key results so far

**2026-08-17 —** So where can I find what this actually did?

**2026-08-17 —** Inspected the BIDS output tree and materialized artifact types; no `.nii` or `.nii.gz` files were produced.

**2026-08-17 —** Can you upload the latest documentation as an MD to my public fork?

**2026-08-17 —** Ok, let's work around this for now. What needs to change to process the image we found?

**2026-08-17 —** Let's plan it out with the openNeuro datasets. What do I need to do?

**2026-08-17 —** What's symlink?

**2026-08-17 —** Symbolic Link? Makes sense. Give me the Nat version definitions of the top 10 terms or acronyms you've been using

**2026-08-17 —** DAG, just like in Databricks? Apptainer sounds like fancy docker.

**2026-08-17 —** Let's throw the new plan into the documentation on GitHub, update the decision log, add prompts, add the Nat definitions at the end

# 1. Purpose

NormaBRAIN already does the hard scientific thing: it takes messy scanner output and converts it into a reproducible neuroimaging workflow with explicit modality-specific processing, registration, segmentation, quantitative maps, and statistics. The fork is not an attempt to “modernize” that science by replacing it with whatever framework we currently think is sexy. The first job is to understand the machine, reproduce it, preserve the domain knowledge, and then make the machine easier to inspect, operate, interrogate, and extend.

The working hypothesis is that NormaBRAIN can become more than a workflow runner. It can become a legible computational model of how a brain measurement came into existence: scanner → acquisition → representation → preprocessing → transformation → derived artifact → measurement → analysis. That lineage is useful before ML, during ML, and after ML because it preserves the conditions under which a number became meaningful.

physical brain + scanner interaction  
↓  
DICOM acquisition reality  
↓  
BIDS canonical representation  
↓  
modality-specific transformations  
↓  
registered / segmented / quantitative artifacts  
↓  
measurements and features  
↓  
analysis / ML

# 2. Why This Is Very Obviously Related to MediLacra

The overlap is structural, not cosmetic. MediLacra and NormaBRAIN both sit at the boundary where physical or operational reality becomes machine representation. Both systems have to preserve meaning while data changes shape. That is the recurring obsession: what relationships survive transformation, what context gets lost, and how do we know whether a derived representation still refers to the same thing?

MediLacra began as a synthetic healthcare data generator, but its useful core has been expanding toward a Reality Model: semantic concepts, reusable generators, identities, relationships, cardinality, constraints, context, events, and schema bindings. The important move is from “call entity generators in a hard-coded sequence” to “state a semantic requirement and resolve the facts, dependencies, identities, and relationships necessary to make that reality coherent.”

MediLacra today-ish  
entity generator  
↓  
dataclass  
↓  
HL7 / database representation

MediLacra Reality Model direction  
semantic requirement  
↓  
existing fact / generator / relationship  
↓  
shared reality state  
↓  
validated downstream representations

NormaBRAIN is already doing an analogous move in another domain: scanner-specific DICOM reality is normalized into BIDS and then transformed into analytical derivatives. BIDS plays a role similar to a canonical representation layer. It is not the brain, just as an HL7 segment is not a patient. It is a disciplined representation whose value comes from preserving enough invariants that later work can be trusted.

| Concern | MediLacra | NormaBRAIN | Reusable idea |
|---|---|---|---|
| Messy source reality | Synthetic clinical/operational world, source schemas, HL7 profiles | Scanner acquisitions, DICOM series, Siemens protocol metadata | Separate reality from representation |
| Canonicalization | Shared semantic facts / future RealityContext | BIDS organization and metadata | Normalize once, preserve provenance |
| Identity | Patient, encounter, order, observation, transaction identifiers | Subject, session, acquisition, series, artifact identity | Explicit namespaces and stable keys |
| Relationships | Patient→encounter→order/result/charge | Subject→session→acquisition→derived artifact | Relationships are data, not glue code |
| Constraints | Referential, cardinality, temporal | Acquisition dependencies, modality requirements, transform lineage | Make validity explicit |
| Execution | Generators + pipelines | Snakemake DAG + Conda + Apptainer | Do not duplicate orchestration |
| Persistence | DuckDB experiments / registries | Mostly filesystem + workflow state | Persist observation and provenance |

# 3. Relation to the Recent Canonical-vs-Bespoke Experiments

The structured-sparsity / canonical-vs-bespoke experiments asked a deceptively simple question: when semantically identical reality is represented differently, what changes in compute, materialization, joins, human comprehension, and state propagation? NormaBRAIN gives us a much richer natural laboratory for the same question because MRI processing is transformation-heavy by definition.

A DICOM series, BIDS dataset, corrected image, registered volume, segmentation, ROI statistic, and ML feature can all refer to the same underlying acquisition while carrying radically different structure and computational affordances. The fork gives us a place to measure not only the output but the transformation cost and semantic lineage between representations.

- Reuse the “unit is the task, not the cost” framing when we benchmark workflow operations.
- Treat each representation as a projection of a shared acquisition reality rather than as an isolated file.
- Preserve materialization ratios, query/workflow cost, state propagation, and semantic fidelity as candidate experiment dimensions.
- Do not invent a grand cognition metric before the system emits enough evidence to justify one.

# 4. Existing NormaBRAIN Pipeline: What We Are Inheriting

The upstream project is a multimodal MRI preprocessing and analysis pipeline centered on Snakemake. Its job is substantially larger than “DICOM processor.” The current architecture encodes domain decisions about scanner field strength, acquisition protocols, modality detection, preprocessing, registration, segmentation, and statistics.

Siemens DICOMs  
↓  
organize / symlink by field strength  
↓  
BIDS conversion + metadata enrichment  
↓  
modality detection  
↓  
MP2RAGE | ihMT | qMT | DWI | QSM | B1  
↓  
registration + segmentation  
↓  
quantitative maps / ROI statistics / derivatives

| Component | Current role | Initial stance |
|---|---|---|
| Bash launcher | Human-facing CLI; converts flags/config into Snakemake execution | Keep temporarily; reduce authority later |
| Snakemake | Workflow DAG, dependency resolution, targets, resources, execution | Keep. This is the execution source of truth. |
| Conda / Miniforge | Python and package environments | Keep. |
| Apptainer / Singularity | Containerized scientific/HPC tools | Keep unless actual evidence says otherwise. |
| BIDS / PyBIDS | Canonical neuroimaging organization and query layer | Keep; understand deeply before extending. |
| Python scripts | Custom metadata and processing logic | Inspect, test, extract reusable seams. |
| Git submodules | External scientific code dependencies | Keep where useful; remove avoidable auth coupling. |
| YAML configuration | Declarative workflow configuration | Keep for config; do not use as operational state. |

# 5. Baseline First: No Heroic Refactor Before Reproduction

The first engineering rule is boring on purpose: reproduce upstream before changing upstream. Otherwise every failure becomes epistemically muddy. Was the environment wrong? Was the original workflow already brittle? Did our cleanup break it? Did the scanner data violate an assumption? We want those questions separable.

clone  
→ resolve submodules  
→ build Linux environment  
→ install / test Apptainer  
→ resolve Snakemake DAG  
→ dry run  
→ BIDS-only execution  
→ limited modality execution  
→ baseline reproduced  
→ THEN start cutting

Windows-native execution was discarded as the reference runtime after the first environment resolved on win-64. The working runtime is WSL2/Linux with a native Linux clone. Miniforge provides Conda/Mamba inside WSL. This matches the scientific/HPC assumptions of Apptainer and the broader toolchain.

# 6. First Cleanup Pass: Remove Accidental Complexity

The first cleanup phase should be aggressively unglamorous. We are not redesigning neuroimaging. We are shaving off environmental assumptions and duplicated control logic that make the pipeline harder to reproduce than the science requires.

1. Fix public git submodules that currently require SSH authentication. Public dependency → public HTTPS clone. This is the first confirmed portability defect.
2. Document a single supported local-development path: WSL2/Linux + Miniforge + Apptainer + native Linux clone.
3. Identify which YAML values are true declarative configuration and which are secretly carrying state or history.
4. Inventory shell logic in the launcher. Anything that is only argument parsing, validation, or structured config handling is a candidate to move into Python/Streamlit later.
5. Make dry-run and DAG inspection first-class developer operations.
6. Add lightweight run observability before altering scientific rules: start, stop, target, command, environment, status, artifacts, error.

The governing distinction is simple: configuration is allowed to be static and version-controlled; observed runtime state should be queryable. YAML is fine for declarative intent. YAML is not a database just because it has indentation.

# 7. Solve Problems Once: MediLacra Reuse Strategy

We should reuse concepts and implementation patterns from MediLacra where they are genuinely domain-agnostic. We should not copy healthcare names into neuroimaging because “reuse” is not the same thing as “smear one ontology across everything.” The reusable layer is the infrastructure for identity, provenance, relationship, constraint, event, registry, and inspection.

| MediLacra piece / idea | Potential NormaBRAIN reuse |
|---|---|
| Semantic registry | Name concepts independently from one file format or workflow rule. |
| Identity namespace pattern | Stable IDs for subject/session/acquisition/run/artifact/transform/measurement. |
| Relationship registry | Declare source→target relationships rather than infer lineage from paths. |
| RealityContext pattern | Resolve and cache shared metadata/context once per computational reality. |
| Constraint classes | Referential, cardinality, temporal/ordering validity for pipeline facts. |
| Event history | Record acquisition/process/artifact events explicitly instead of reconstructing them from filesystem timestamps. |
| DuckDB persistence | Run registry, artifact registry, provenance, QC, feature tables, benchmark results. |
| Streamlit control surface | Human legibility and bounded intervention over an existing engine. |
| Schema-binding mindset | BIDS entities/metadata and Snakemake rules bind to concepts rather than becoming the concepts. |
| Canonical-vs-bespoke benchmark harness | Measure representation and workflow tradeoffs rather than argue aesthetically. |

MediLacra already contains primitive forms of many of these ideas: Patient/Encounter/Observation/Transaction dataclasses; IDs passed between generators; DuckDB tables/indexes; scenario profiles for organizations, facilities, departments and routing; temporal constraints embedded in generators; and an IRIS HL7 schema parser that extracts messages, segments, fields, datatypes, requiredness, repetition, components and coded tables. The Reality Model work is therefore an extraction and unification problem more than a greenfield ontology project. NormaBRAIN should benefit from the same discipline.

# 8. Target Direction: NormaBRAIN Workbench

The likely end state is a Workbench wrapped around, not substituted for, the scientific workflow. Snakemake remains authoritative for what must execute. BIDS remains authoritative for standardized imaging representation. DuckDB records what actually happened. Streamlit makes the system legible and gives humans a control surface.

Streamlit Workbench  
datasets | subjects | sessions | QC | runs  
│  
control / inspection layer  
│  
┌──────────────┴──────────────┐  
│ │  
DuckDB Snakemake  
state + provenance execution DAG  
│ │  
└──────────────┬──────────────┘  
│  
BIDS + derived artifacts  
│  
Conda / Apptainer / Python

# 9. Proposed DuckDB Operational Model

Do not start with a universal graph database. A small relational model is enough to make the workflow inspectable and to support ML later.

dataset  
subject  
session  
scanner  
acquisition  
series  
pipeline_run  
pipeline_step  
artifact  
spatial_transform  
metric  
qc_result  
feature  
model  
experiment  
prediction

The important thing is not the table names. The important thing is that every derived artifact can answer: where did I come from, which subject/session/acquisition do I belong to, which code/environment produced me, which transform chain touched me, and which measurements or models consumed me?

# 10. ML Comes After Lineage, Not Before It

The seductive bad path is MRI → neural network → disease label. That is exactly how we throw away the most interesting part of the system. Before training anything serious, the fork should emit machine-readable lineage for every feature or quantitative measurement.

subject 004  
→ session 2  
→ Siemens 7T scanner  
→ DICOM series X  
→ MP2RAGE acquisition + parameters  
→ BIDS conversion  
→ correction  
→ spatial transform  
→ segmentation  
→ ROI  
→ R1 measurement = X

Then an ML row is not merely hippocampus_R1 = 0.73. It retains the conditions under which 0.73 came into existence. That gives us a fighting chance of distinguishing biology from scanner effects, preprocessing effects, protocol changes, transform choices, and other confounders.

# 11. OpenNeuro Downstream Baseline Plan

The foreign Siemens DICOM probe taught us something useful but also showed that `bidsify.done` can be semantically hollow: the control path can succeed without materializing image data. While we wait for Ryn’s reference DICOM fixture, the next experiment should test the other side of the architectural boundary directly.

The key move is to treat **BIDS as the contract between ingestion and downstream science**.

```text
PATH A — native NormaBRAIN path
DICOM
→ NormaBRAIN bidsify
→ BIDS
→ downstream modality processing

PATH B — portability test path
OpenNeuro BIDS
→ PyBIDS discovery
→ downstream modality processing
```

This is not yet a permanent feature. First we prove manually that a foreign, standards-conforming BIDS dataset can be discovered and consumed downstream. Only then do we encode the path into the launcher or Workbench.

## Why OpenNeuro

OpenNeuro gives us public BIDS datasets where the DICOM→BIDS normalization has already occurred. That lets us isolate downstream compatibility from NormaBRAIN’s scanner/lab-specific ingestion assumptions.

The first target should be **DWI**, not MP2RAGE.

MP2RAGE in NormaBRAIN expects a specific acquisition family: MP2RAGE suffixes, inversion images, UNIT1, and B1 mapping data. That is appropriate for the science, but it makes it a poor first portability probe.

DWI is still opinionated, but its contract is easier to search for and inspect. We want a small OpenNeuro dataset containing:

```text
Siemens scanner
BIDS compliant
DWI
.nii.gz image data
.json sidecars
.bvec gradients
.bval gradients
ideally AP + PA phase-encoding directions
```

## Bounded procedure

1. Select a small OpenNeuro Siemens dataset with DWI, ideally AP/PA paired acquisitions.
2. Download one subject, not the whole cohort.
3. Stage it outside the repo under `~/normabrain_test/openneuro/`.
4. Inspect the BIDS hierarchy and filenames before involving NormaBRAIN.
5. Copy the dataset metadata and one subject into `data/rawdata/bids/3T/` for the first test. Use boring physical files first; optimize disk use later.
6. Query the staged dataset directly with PyBIDS to verify subject/session/acquisition discovery.
7. Call Snakemake directly against the DWI aggregate target with `--dry-run`, bypassing `run_workflow.bash` because the current Bash launcher always invokes bidsify first.
8. If the DAG materializes, remove `--dry-run` and observe the first real downstream failure or derivative.
9. Preserve every failure as evidence about where the actual portability boundary lives.

The expected diagnostic ladder is:

```text
PyBIDS cannot see dataset
→ fixture/layout problem

PyBIDS sees dataset, NormaBRAIN finds no jobs
→ NormaBRAIN naming/entity assumption

DAG builds but input lookup fails
→ stricter acquisition / AP-PA assumptions

containers start and processing fails
→ scientific/tool compatibility boundary

derivatives materialize
→ downstream portability demonstrated
```

## Candidate future interface

If the manual experiment works, the launcher/Workbench should eventually expose the semantic distinction explicitly:

```text
input_mode = dicom | bids
```

or, in the Workbench:

```text
Source type:
- Raw DICOM
- Existing BIDS
```

The critical constraint is that we do **not** build this switch before the BIDS→downstream path is empirically validated. We are encoding a proven seam, not inventing a prettier abstraction and hoping reality cooperates.

# 12. Milestones

| Phase | Goal | Exit condition |
|---|---|---|
| 0 — Reproduce | Run upstream locally without architectural changes | Submodules, Conda, Apptainer, DAG and at least one bounded pipeline path work in WSL2. |
| 0A — Downstream portability probe | Test foreign existing-BIDS input independently of bidsify | PyBIDS discovers a public OpenNeuro subject and at least one downstream NormaBRAIN DAG resolves. |
| 1 — Portability cleanup | Remove accidental environment coupling | Clean clone works without GitHub SSH; setup is documented and repeatable. |
| 2 — Observe | Persist runs and artifacts without changing science | DuckDB run/artifact registry records actual executions. |
| 3 — Legibility | Build read-only Streamlit inspection surface | Datasets, subjects, sessions, runs, artifacts and failures can be explored. |
| 4 — Control | Move bounded launcher operations into Workbench | Users can choose pipeline targets and launch Snakemake without shell flag archaeology. |
| 5 — Provenance | Model acquisition→artifact lineage explicitly | Derived measurements can be traced back to source acquisition and transforms. |
| 6 — Feature product | Produce stable cross-subject feature tables | Feature extraction is reproducible, queryable and lineage-aware. |
| 7 — ML experiments | Add experiment/model registry and controlled tests | Models consume provenance-aware features with reproducible splits/configuration. |
| 8 — Weird science | Use the platform for representation/cognition experiments | Experiments test real hypotheses instead of decorating the pipeline. |

# 13. Guardrails

- Do not replace Snakemake just because we can write Python.
- Do not reinterpret BIDS before learning what invariants it actually protects.
- Do not turn DuckDB into a second workflow engine.
- Do not let Streamlit become the only way to run the pipeline; the engine should remain independently operable.
- Do not hide scientific parameters behind UI defaults without preserving them in provenance.
- Do not copy MediLacra-specific healthcare ontology into brains. Reuse infrastructure, not category mistakes.
- Do not begin serious ML until feature provenance and dataset boundaries are explicit.
- Do not confuse a prettier interface with a better scientific system.
- Do not “fix” the launcher to support existing BIDS until a manual BIDS→downstream path actually works.
- Keep ingestion compatibility and downstream scientific compatibility as separate questions.

# 14. Baseline Results and Findings — 2026-08-17

The first bounded execution path now runs on a clean WSL2/Linux environment. This is an operational baseline, not yet a scientific validation of the resulting imaging artifacts. The inherited machinery can be installed, parsed, scheduled, and driven through its nominal BIDS target on a foreign public Siemens dataset without modifying NormaBRAIN’s scientific rules. Artifact inspection then exposed an important distinction: Snakemake target completion does **not** currently guarantee that imaging data were actually materialized.

## Environment / execution baseline

- WSL2/Linux reference runtime confirmed on `natdata`.
- Native Linux Miniforge installation working with Conda 26.3.2 and Mamba 2.5.0.
- Pinned NormaBRAIN environment resolved with Python 3.14.6, Snakemake 9.23.1, and Graphviz 14.1.2.
- Conda channel priority set to `strict` after Snakemake warned that reproducible environment resolution depends on it.
- Apptainer 1.5.3 installed successfully under WSL2.
- Independent Apptainer smoke test succeeded by pulling `docker://alpine`, converting it to SIF, executing it, and returning Alpine 3.24.1.
- NormaBRAIN dry-run parsed the Snakefile, loaded configuration, resolved the BIDS target, and correctly exposed its checkpoint-driven dynamic DAG.

## Foreign Siemens sacrificial test

While waiting for a deidentified NormaBRAIN reference dataset from Ryn, we intentionally used the public `neurolabusc/dcm_qa_xa30` Siemens Prisma Fit XA30 dataset as a portability probe. This is not the gold-standard reproduction fixture; it is foreign Siemens data chosen specifically to see where environmental and ingestion assumptions break.

The first attempt failed before DICOM parsing because our test wrapper placed the dataset behind a symlinked directory. The ingestion script searches each session with `Path.rglob('*.dcm')` and did not descend through that symlink boundary, producing an unhandled `IndexError` when it indexed an empty result list. We corrected the fixture by copying the directory into the expected physical hierarchy and deliberately did not alter NormaBRAIN code during baseline establishment.

**NB-BL-001 — Input traversal assumes a physical root → subject → session → DICOM hierarchy.** A session whose DICOM-bearing subtree is exposed only through a symlinked directory is not discovered; the current failure mode is an unhandled `IndexError` rather than an intelligible validation error. Record now, fix later.

## BIDS-only execution result

After correcting the fixture, Snakemake completed the nominal BIDS path 5/5:

- `symlink_dicoms_by_field_strength` completed and classified the public test subject as 3T.
- `bidsmapper` completed and wrote a generated bidsmap for the 3T dataset.
- BIDSmapper emitted one template-validity warning: `Not all datatypes and options in the template bidsmap are valid`. This is evidence to inspect, not a reason to silently normalize the template during baseline work.
- BIDScoiner 4.6.2 completed and created dataset scaffolding including `dataset_description.json`, `README`, `participants.json`, `participants.tsv`, and the subject/session scans table.
- CSA metadata enrichment completed. nibabel emitted its own warning that the Siemens DICOM readers used by the CSA parser are experimental/unstable; the rule nevertheless completed successfully.
- `gather_add_csa_data_to_meta` produced `data/rawdata/bidsify.done`.
- Snakemake reported all five jobs successful.

Artifact inspection immediately afterward showed that **no `.nii` or `.nii.gz` imaging files were created**. The materialized BIDS tree contained metadata/scaffolding only:

```text
data/rawdata/bids/3T/
├── README
├── code/bidscoin/...
├── dataset_description.json
├── participants.json
├── participants.tsv
└── sub-testsubject/ses-1/sub-testsubject_ses-1_scans.tsv
```

The earlier BIDSmapper log had already reported `No dcm2niix2bids sourcedata found`, which is consistent with the absence of converted images.

**NB-BL-002 — Workflow success does not imply image materialization.** The current BIDS completion condition can reach `bidsify.done` even when no NIfTI imaging artifacts are produced. Operational completion, artifact completeness, and scientific validity are therefore three distinct states and must remain distinct in future observability/control-plane work.

## What this establishes

The environment and orchestration baseline is strong: NormaBRAIN installs, resolves environments, executes checkpoints, identifies scanner field strength, drives BIDScoin, enriches metadata, and closes its nominal BIDS target under WSL2. The foreign XA30 test does **not** yet establish successful DICOM→BIDS image conversion, because the expected NIfTI artifacts were absent.

```text
environment                              → PASS
Snakemake parse / dynamic DAG             → PASS
Apptainer execution                       → PASS
foreign Siemens ingestion / 3T detection  → PASS
nominal BIDS workflow target              → PASS
actual NIfTI image materialization         → NOT OBSERVED
NB-BL-001 symlink traversal                → RECORDED
NB-BL-002 completion-vs-materialization    → RECORDED
Ryn reference-data reproduction            → WAITING ON FIXTURE
OpenNeuro existing-BIDS probe              → PLANNED
modality-specific processing               → NOT YET TESTED
```

This is exactly why baseline work precedes cleanup: the system can truthfully say “workflow completed” while a human inspecting the artifact layer discovers that the substantive image conversion never occurred. That semantic gap is now part of the evidence, not something we have accidentally paved over.

# 15. Decision Log

| Date | Decision | Reason |
|---|---|---|
| 2026-08-16 | Fork rather than rebuild | Preserve Ryn’s domain work; investigate structure before intervention. |
| 2026-08-16 | Keep Snakemake | It is already the workflow/dependency source of truth. |
| 2026-08-16 | Keep Conda | Appropriate scientific dependency isolation; already embedded in project. |
| 2026-08-16 | Keep Apptainer initially | Matches Linux/HPC scientific packaging needs. |
| 2026-08-16 | Treat BIDS as canonical representation, not ontology | It standardizes imaging data without becoming “the brain.” |
| 2026-08-16 | Streamlit is future control surface | Human legibility/control without duplicating orchestration. |
| 2026-08-16 | DuckDB for operational/provenance state | Queryable state belongs in a database; declarative config can remain YAML. |
| 2026-08-16 | Baseline first | Reproduce before refactoring to keep failures attributable. |
| 2026-08-16 | WSL2/Linux is reference local runtime | Apptainer and scientific stack are Linux-native. |
| 2026-08-16 | Use native WSL clone | Avoid mixed Windows/Linux filesystem/runtime behavior. |
| 2026-08-16 | Miniforge in WSL | Separate Linux Conda/Mamba from Windows Conda. |
| 2026-08-16 | Public submodules should use HTTPS | Do not require SSH identity for public dependencies. |
| 2026-08-17 | Reuse MediLacra infrastructure selectively | Solve identity/provenance/registry/control-plane problems once; preserve domain semantics. |
| 2026-08-17 | Set Conda channel priority to strict | Snakemake explicitly warned that strict priority is important for robust, correct environment resolution. |
| 2026-08-17 | Use a public Siemens XA30 dataset as a sacrificial portability probe | Keep moving while waiting for Ryn’s reference fixture; foreign data tests plumbing and assumptions without pretending to reproduce NormaBRAIN science. |
| 2026-08-17 | Fix the test fixture before changing ingestion code | Baseline attribution matters. The symlink traversal failure came from our wrapper, so we corrected the wrapper and preserved upstream behavior. |
| 2026-08-17 | Record symlink traversal as NB-BL-001 and defer the code fix | The failure is a real robustness defect, but modifying it before reproduction would muddy the baseline. |
| 2026-08-17 | Treat BIDS target completion as operational success, not scientific validation | The workflow reached bidsify.done on foreign Siemens data; artifact completeness and semantic correctness still require inspection. |
| 2026-08-17 | Record completion-vs-materialization gap as NB-BL-002 | Artifact inspection found no NIfTI outputs despite a 5/5 successful BIDS target; workflow status, artifact completeness, and scientific validity must be modeled separately. |
| 2026-08-17 | Treat BIDS as an explicit ingestion/analysis contract boundary | Existing BIDS should be able to enter downstream of scanner-specific DICOM normalization if the downstream rules truly depend on BIDS rather than on hidden ingestion state. |
| 2026-08-17 | Use OpenNeuro for the next downstream portability probe | Public BIDS data lets us test PyBIDS + modality processing independently from the failed foreign DICOM conversion path. |
| 2026-08-17 | Start the OpenNeuro probe with DWI | DWI has a simpler observable BIDS contract than NormaBRAIN’s MP2RAGE path, while still exercising real scientific tooling and containers. |
| 2026-08-17 | Copy the first OpenNeuro subject instead of symlinking it | Baseline tests should minimize filesystem ambiguity; optimize storage only after the path works. |
| 2026-08-17 | Call Snakemake directly for the first existing-BIDS test | `run_workflow.bash` currently always executes bidsify first, which is exactly the stage we want to bypass in this experiment. |
| 2026-08-17 | Defer `input_mode=dicom|bids` until manual proof exists | Encode a seam only after reality demonstrates that the seam is real. |

# 16. Current State

Fork created DONE  
Architecture inspected DONE  
WSL2 reference runtime DONE  
Linux Git DONE  
Miniforge / Conda / Mamba DONE  
Native WSL clone DONE  
Submodules resolved locally DONE  
Permanent public-submodule HTTPS fix TODO  
Linux Snakemake environment DONE  
Conda strict channel priority DONE  
Apptainer 1.5.3 DONE  
Apptainer container smoke test DONE  
Snakemake DAG / dry run DONE  
Foreign Siemens fixture prepared DONE  
NB-BL-001 recorded DONE  
BIDS-only foreign-data execution DONE (5/5 jobs; nominal target only)  
BIDS artifact/content inspection DONE — metadata/scaffolding only; no NIfTI images observed  
NB-BL-002 recorded DONE  
OpenNeuro DWI fixture selection TODO  
OpenNeuro one-subject staging TODO  
Independent PyBIDS discovery test TODO  
Existing-BIDS DWI Snakemake dry-run TODO  
Existing-BIDS DWI real execution TODO  
Ryn reference dataset requested WAITING  
Reference-data BIDS reproduction WAITING  
Limited modality execution TODO  
Baseline reproduced PARTIAL — operational path passed; reference science pending  
Architecture changes TODO

# 17. Working Thesis

NormaBRAIN should become an inspectable neuroimaging data system without ceasing to be Ryn’s neuroimaging pipeline. The science remains primary. Our intervention is to make transformations explicit, provenance durable, state queryable, and execution legible. MediLacra provides reusable machinery and habits for doing that, but not a preordained brain ontology.

The common object across both projects is not “healthcare data.” It is represented reality: physical and social processes passing through lossy technical systems while we try to preserve enough identity, relationship, context, and provenance to still know what the hell the numbers mean.

# 18. Nat Definitions: The Working Vocabulary

These are deliberately material definitions: what the thing is, what job it does, and where it sits in the machine.

## 1. DICOM — Digital Imaging and Communications in Medicine

The scanner’s native-ish output package. Not just “an image”: a DICOM file can carry pixels **plus a pile of metadata** about the machine, acquisition, timing, field strength, sequence, patient/study identifiers, and other scanner context.

**Nat compression:** scanner exhaust with receipts attached.

## 2. BIDS — Brain Imaging Data Structure

A convention for turning neuroimaging chaos into a predictable filesystem, naming scheme, and metadata structure. It says roughly: this is subject X, session Y, acquisition Z, modality Q, and here is the metadata that explains it.

It is not biological reality. It is a disciplined canonical representation of imaging data.

**Nat compression:** the canonical warehouse model for brain imaging.

## 3. NIfTI / `.nii.gz` — Neuroimaging Informatics Technology Initiative format

The multidimensional image volume most downstream analysis tools actually want. A structural MRI becomes essentially a voxel array with spatial metadata; functional and diffusion data can add dimensions. `.nii.gz` is compressed NIfTI.

**Nat compression:** the voxel matrix after we stop caring about the scanner’s weird packaging.

## 4. Snakemake

The workflow engine. Rules describe outputs, inputs, and the transformations connecting them; Snakemake resolves what has to happen and in what dependency order.

**Nat compression:** the execution brain of NormaBRAIN.

## 5. DAG — Directed Acyclic Graph

A dependency topology where edges have direction and dependencies cannot loop back into themselves. Same underlying concept as a Databricks job/task DAG.

```text
raw image
→ preprocess
→ register
→ segment
→ statistics
```

If segmentation requires registration, the graph makes that ordering explicit.

**Nat compression:** dependency topology. Same mathematical object Databricks uses, different workload.

## 6. Conda / Miniforge / Mamba

Related but distinct pieces:

- **Conda** manages environments and packages.
- **Miniforge** is a lightweight Conda distribution centered on conda-forge.
- **Mamba** is a faster Conda-compatible package/environment solver and interface.

They answer: which exact Python and libraries does this computational step get?

**Nat compression:** every scientific module gets its own little software terrarium.

## 7. Apptainer / Singularity

A container runtime built heavily around scientific and HPC execution. Same basic isolation idea as Docker, but designed for shared clusters and research environments where root-heavy Docker assumptions are often undesirable. It can consume Docker/OCI images.

**Nat compression:** fancy Docker for people who submit jobs to supercomputers.

More mechanically:

```text
Snakemake = what runs and in what dependency order
Conda     = package/library environment
Apptainer = whole software-container environment
```

## 8. PyBIDS

A Python library that understands BIDS semantically. Instead of manually scraping paths, code can ask for subjects, sessions, acquisitions, suffixes, modalities, and files through the BIDS model.

**Nat compression:** SQL-ish semantic access to a BIDS filesystem without actually putting it in SQL.

## 9. DWI — Diffusion-Weighted Imaging

An MRI acquisition family designed to measure how water diffusion behaves in tissue. Because tissue structures constrain movement, DWI can expose information about microstructure and white-matter organization. It usually involves many volumes acquired with different diffusion gradients.

**Nat compression:** instead of asking what a voxel looks like, ask how water preferentially moves through it.

## 10. MP2RAGE — Magnetization Prepared 2 Rapid Acquisition Gradient Echoes

A specific structural MRI acquisition technique that combines multiple inversion-weighted measurements to derive better-behaved structural/T1-related information and reduce some acquisition biases. NormaBRAIN’s MP2RAGE path expects a specific family of related images and B1 information.

**Nat compression:** not “an MRI”; a specific experimental recipe for interrogating tissue.

## Bonus: Symlink — Symbolic Link

A filesystem object whose content is basically: **the real thing is over there**. Multiple paths can refer to one physical dataset without duplicating its bytes.

```text
visible path in project
→ symbolic link
→ real files somewhere else
```

Useful for giant imaging datasets, but only if the consuming code actually follows symlinked directories the way you expect. NB-BL-001 exists because one NormaBRAIN ingestion path did not.

**Nat compression:** filesystem pointer; elegant until somebody’s traversal code decides not to follow it.

## The whole stack in one picture

```text
DICOM
scanner representation
    ↓
BIDS
canonical organization
    ↓
NIfTI
analysis-friendly image representation
    ↓
PyBIDS
semantic discovery/query
    ↓
Snakemake DAG
what transformations must happen
    ↓
Conda + Apptainer
what software reality each transformation runs inside
    ↓
DWI / MP2RAGE / qMT / etc.
specific scientific measurement pipelines
```
