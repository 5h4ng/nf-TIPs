.PHONY: clean clean-work clean-logs clean-results

clean: clean-work clean-logs clean-results

clean-work:
	rm -rf work .nextflow

clean-logs:
	rm -f .nextflow.log*

clean-results:
	rm -rf Results reports


