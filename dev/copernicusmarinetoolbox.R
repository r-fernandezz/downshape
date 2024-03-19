


copernicus_download_api(path_tab_param="data/copernicus_parameters_modified.csv")




copernicus_download_api <- function(path_tab_param,
                                    septime = "month",
                                    nb_retry = 100,
                                    user = "ajeager",
                                    passwd = "madzeD-4xozqo-mipsyh") {
  
    library(lubridate)
    
    # Remove folder and creat a folder empty
    path_output <- here::here("output", "data_copernicus")
    if(!file.exists(path_output)) dir.create(path_output, showWarnings = FALSE)
    
    # check encodage csv
    if(ncol(read.csv2(path_tab_param)) < 2){ 
      tab_param <- read.csv(path_tab_param)
    }else(tab_param <- read.csv2(path_tab_param))
    
    # Creat python command and download by table row
    for(i in 1:nrow(tab_param)){
      
        message(paste0("Traitement of ", tab_param[i, "my_variable_name"], " variable"))
        
        command <- paste("/opt/miniconda3/envs/R_env/bin/copernicusmarine subset -i ")
  
        
        if(!is.na(tab_param[i, "product_id"])){
          command <- paste0(command, tab_param[i, "product_id"])
        }else("product_id parameter doesn't exist")
        
        if(!is.na(tab_param[i, "longitude_min"])){
          command <- paste0(command, " -x ", tab_param[i, "longitude_min"])
        }else("longitude_min parameter doesn't exist")
        
        if(!is.na(tab_param[i, "longitude_max"])){
          command <- paste0(command, " -X ", tab_param[i, "longitude_max"])
        }else("longitude_max parameter doesn't exist")
        
        if(!is.na(tab_param[i, "latitude_min"])){
          command <- paste0(command, " -y ", tab_param[i, "latitude_min"])
        }else("latitude_min parameter doesn't exist")
        
        if(!is.na(tab_param[i, "latitude_max"])){
          command <- paste0(command, " -Y ", tab_param[i, "latitude_max"])
        }else("latitude_max parameter doesn't exist")
        
        if(!is.na(tab_param[i, "date_min"])){
          command <- paste0(command, " -t ", date(dmy_hm(tab_param[i, "date_min"])))
        }else("date_min parameter doesn't exist")
        
        if(!is.na(tab_param[i, "date_max"])){
          command <- paste0(command, " -T ", date(dmy_hm(tab_param[i, "date_max"])))
        }else("date_max parameter doesn't exist")
        
        if(!is.na(tab_param[i, "depth_min"])){
          command <- paste0(command, " -z ", tab_param[i, "depth_min"])
        }else("depth_min parameter doesn't exist")
        
        if(!is.na(tab_param[i, "depth_max"])){
          command <- paste0(command, " -Z ", tab_param[i, "depth_max"])
        }else("depth_max parameter doesn't exist")
        
        if(!is.na(tab_param[i, "variable"])){
          command <- paste0(command, " --variable ",tab_param[i, "variable"])
        }else("variable parameter doesn't exist")
        
        command <- paste0(command, 
                          " -o ", path_output, 
                          " -f ", tab_param[i, "variable"], "_", tab_param[i, "service_id"], "_", 
                          strsplit(gsub("/", "", tab_param[i, "date_min"]), " ")[[1]][1], "-", 
                          strsplit(gsub("/", "", tab_param[i, "date_max"]), " ")[[1]][1], ".nc", 
                          " --force-download --username ", user,
                          " --password ", passwd)
        
        message("Downloading... Launch command : \n", "---> ", command)
        
        # Download and check file downloaded
        system(command, inter = TRUE)
        }
}
    