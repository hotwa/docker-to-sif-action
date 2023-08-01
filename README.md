# Dockerfile to SIF Github Action

This action builds a SIF file from a Dockerfile and optionally signs it.

## Inputs

### `dockerfile_path`

**Required** The path to the Dockerfile. 

### `apptainer_key`

The Apptainer key for signing. This is optional, and if not provided, the action will skip the signing step.

## Usage

```yml
- uses: hotwa/docker-to-sif-action@v1.0
  with:
    dockerfile_path: path/to/your/Dockerfile
    apptainer_key: ${{ secrets.APPTAINER_KEY }} # optional
```
