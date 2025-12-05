This is the final project for BIOS611. In this report, we used the public data that contained the cuisine and the inspection type in New York City. By using this data, we applied multiple datascience technique to investigate the trend of restaurant types, the restaurant type that violets code the most and severest. Finally, we applied the language the model for cuisine type prediction for the sake of future use.  

docker build -t project
docker run -v $(pwd):/home/rstudio/work -p 8787:8787 project

To build the report.html, go to the makefile and go to the terminal. Run make report.html. Then the generation will begin. (Note that it will take a while for the bootstrap take effect)
The whole project is organized in a makefile. We created each chunk in order to output the separate results we want inside the makefile. Finally we use Rscript to make sure that they run successfully.
Embedding can be found here "https://colab.research.google.com/drive/1TUadh9cmyKGQwrI9rBd3hmLZI9wHFBe4"

