.PHONY: clean

clean: 
	rm -rf figures
	mkdir figures
	rm report.html

.PHONY: dir

dir: 
	mkdir -p figures
    
figures/trend.png: trend_figure.R DOHMH_New_York_City_Restaurant_Inspection_Results.csv | dir
	Rscript trend_figure.R

figures/violation_frequency.png: violation_freq.R DOHMH_New_York_City_Restaurant_Inspection_Results.csv | dir
	Rscript violation_freq.R
	
figures/avg_vio.png: avg_vio.R DOHMH_New_York_City_Restaurant_Inspection_Results.csv | dir
	Rscript avg_vio.R

build_model.rds: build_model.R DOHMH_New_York_City_Restaurant_Inspection_Results.csv name_embeddings_unique_camis.csv | dir
	Rscript build_model.R

major.txt acc.txt: xgboost.R build_model.rds | dir
	Rscript xgboost.R

figures/auc.png: auc.R build_model.rds | dir 
	Rscript auc.R

report.html: report.Rmd figures/trend.png figures/violation_frequency.png figures/avg_vio.png build_model.rds major.txt acc.txt figures/auc.png
	R -e "rmarkdown::render('report.Rmd', output_format='html_document')"