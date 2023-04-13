#' make_url
#'
#' @description Construct an url to query the api at https://esgf-node.llnl.gov
#'
#' @param experiments Character. The desired experiments
#' @param freq Character. The desired temporal frequency
#' @param vars Character. The desired variable ids
#' @param time_span
#' @param sources Character. The desired models (sources) ids (may be NULL)
#' @param grids Character. The desired kind(s) of grid
#' @param members
#' @param res_type
#' @param type Character. Tsearch" to query esgf for availaible data info, "wget" to download a bash script
#' @param limit Character. The maximum number of results to return
#' @param offset
#'
#' @return Character. A json query to run over https://esgf-node.llnl.gov
#' 
#' @export NULL

make_url <- function(experiments,
                     freq,
                     vars,
                     time_span = NULL,
                     sources = NULL,
                     grids = NULL,
                     members = NULL,
                     res_type = "Dataset",
                     type = "search",
                     limit = NULL,
                     offset = NULL){
  
  head_s <- switch(type,
                   search = paste0("https://esgf-node.llnl.gov/esg-search/search/?replica=false&latest=true&activity_id=ScenarioMIP%2CCMIP&nominal_resolution=100+km%2C1x1+degree"),
                   wget   = "https://esgf-node.llnl.gov/esg-search/wget?activity_id=ScenarioMIP%2CCMIP&nominal_resolution=100+km%2C1x1+degree"
  )
  
  experiment_s  <- paste0("&experiment_id=", paste(experiments, collapse = "%2C"))
  freq_s <- paste0("&frequency=", freq)
  vars_s <- paste0("&variable_id=", paste(vars, collapse = "%2C"))
  
  if (!is.null(offset)) {
    off_s <- paste0("&offset=", offset)
  } else {
    off_s <- "&offset=0"
  }
  
  if (!is.null(limit)) {
    lim_s <- paste0("&limit=", limit)
  } else {
    lim_s <- "&limit=10000"
  }
  
  if (!is.null(sources)) {
    sources_s <- paste0("&source_id=", paste(sources, collapse = "%2C"))
  } else {
    sources_s <- NULL
  }
  
  if (!is.null(grids)) {
    grid_s <- paste0("&grid_label=", paste(grids, collapse = "%2C"))
  } else {
    grid_s <- NULL
  }
  
  if (!is.null(members)) {
    memb_s <- paste0("&member_id=", paste(members, collapse = "%2C"))
  } else {
    memb_s <- NULL
  }
  
  if (!is.null(time_span) & type != "wget") {
    span_s <- paste0(paste0("&start=", time_span$start), paste0("&end=", time_span$end)) 
  } else {
    span_s <- NULL
  }
  
  body_s <- "&project=CMIP6"
  #facets_s <- "&facets=mip_era%2Cactivity_id%2Cproduct%2Csource_id%2Cinstitution_id%2Csource_type%2Cnominal_resolution%2Cexperiment_id%2Csub_experiment_id%2Cvariant_label%2Cgrid_label%2Ctable_id%2Cfrequency%2Crealm%2Cvariable_id%2Ccf_standard_name%2Cdata_node"
  format_s <- "&format=application%2Fsolr%2Bjson"
  #url <- paste0(head_s, sources_s, experiment_s, freq_s, vars_s, memb_s, grid_s, body_s, switch(type, search = facets_s, wget = NULL), switch(type, search = format_s, wget = NULL), "&latest=true")
  url <- paste0(head_s, off_s,
                switch(type, search = paste0("&type=", res_type), wget = NULL),
                sources_s, experiment_s, freq_s, span_s, vars_s, memb_s, grid_s, body_s,
                switch(type, search = format_s, wget = NULL), "&latest=true",
                lim_s)
  attr(url, "type") <- type
  attr(url, "limit") <- as.numeric(limit)
  url
}


#' query_esgf
#' 
#' @description Query the api https://esgf-node.llnl.gov
#' 
#' @param url a formated http query url
#' @param show_url print the query url
#' @param type Logical.
#' @param verb Logical. Should the function be verbose. indicate number of matches found.
#'
#' @return json list
#'
#' @export NULL

query_esgf <- function( url,
                        type = "search",
                        show_url = TRUE,
                        verb = TRUE) {

  if (attr(url, "type") != type) stop("url type does not match the requested query type")
  if (show_url) message("-- url:\n", url)
  httcont <- httr::content(httr::GET(url))
  if (type == "wget") return(httcont)
  search_res <- jsonlite::parse_json(httcont)
  search_res <- search_res$response$docs
  #class(search_res) <- c("cmip_results", class(search_res))
  if (verb) {
    message("\n-> found: ", length(search_res), " matches")
  }
  search_res
}


#' search_esgf
#'
#' @description Construct urls and query over https://esgf-node.llnl.gov
#' 
#' @param experiments Character. the desired experiments
#' @param freq Character. the desired temporal frequency
#' @param vars Character. the desired variable ids
#' @param time_span
#' @param sources
#' @param grids Character. the desired kind(s) of grid
#' @param members Character. the desired member(s)
#' @param res_type
#' @param type Character. "search" to query esgf for availaible data info, "wget" to download a bash script
#' @param limit Character. the maximum number of results to return
#' @param offset
#' @param verb Logical. should the funciton be verbose ?
#' @param count
#'
#' @return a parsed json list
#' 
#' @export NULL

search_esgf <- function(experiments,
                         freq,
                         vars,
                         time_span = NULL,
                         sources   = NULL,
                         grids     = NULL,
                         members   = NULL,
                         res_type  = "Dataset",
                         type      = "search",
                         limit     = 10000,
                         offset    = 0,
                         verb      = TRUE,
                         count     = 0) {
  
  if (verb & count == 0) message("'[-_x]' Searching root ESGF node (https://esgf-node.llnl.gov):\n- experiments in: ",
                    paste(experiments, collapse = ", "),
                    "\n- vars in: ",
                    paste(unlist(vars), collapse = ", "),
                    "\n- freq in: ",
                    paste(freq, collapse = ", "),
                    ifelse(is.null(time_span), "", paste0("\n- time span: ", paste0(time_span$start, " -> ", time_span$end))),
                    ifelse(is.null(sources), "", paste0("\n- sources in: ", paste(sources, collapse = ", "))),
                    ifelse(is.null(grids), "", paste0("\n- grids in: ", paste(grids, collapse = ", "))),
                    ifelse(is.null(members), "", paste0("\n- members in: ", paste(members, collapse = ", "))),
                    "\n")
  url <- make_url(experiments, freq, vars, time_span, sources, grids, members, res_type, type, limit, offset)
  resp  <- query_esgf(url, type = type, verb = verb)
  n_res <- length(resp)
  # if we reached the limit then we need to search again
  if (n_res == limit) {
    new_count <- count + 1
    new_off <- new_count * limit
    message("\n! reached the query limit (" , limit,") ", new_count, " times, querying again with offset ", new_off, "\n")
    message("last resp element is ", resp[[length(resp)]]$dataset_id, "\n")
    message("sleeping 3s\n")
    Sys.sleep(3)
    return(c(resp, search_esgf(vars = vars,
                           experiments = experiments,
                           freq = freq,
                           verb = verb,
                           time_span = time_span,
                           res_type = res_type,
                           limit = limit,
                           offset = new_off,
                           count = new_count)
           ))
  }
  message("\n")
  
  attr(resp, "experiments") <- experiments
  attr(resp, "freq")        <- freq
  attr(resp, "vars")        <- vars
  attr(resp, "time_span")   <- time_span
  attr(resp, "sources")     <- sources
  attr(resp, "grids")       <- grids
  attr(resp, "members")     <- members
  attr(resp, "res_type")    <- res_type
  
  resp
}

#' cmip_parse_search
#'
#' @description Parse an ESGF json result as a data.frame
#' 
#' @param results an ESGF json result come from search_esgf function.
#'
#' @return a data.frame
#
#' @export NULL

cmip_parse_search <- function(results) {

  # results <- targets::tar_read("available_dataset_json")
  # results <- datasets_todown #output of select_dataset() function

  # keep all possible meta data  

  # here comes the incremental loop (omg)
  cols <- names(results[[1]])
  for (i in 2:length(results)) cols <- union(cols, names(results[[i]])) 
  
  parsed <- parallel::mclapply(results, function(result) {
    d <- data.frame(lapply(result, '[[', 1))
    miss_cols <- cols[!cols %in% names(d)] 
    d[, miss_cols] <- NA
    d
  })
  
  do.call(rbind, parsed)
}

#' get_models_for_experiment
#'
#' @description Get models with all variables available by experiments. The function keep model if speed variables or component variables are availables.
#'
#' @param res Table. Output of cmip_parse_search function (and search_esgf function before)
#' @param experiment Character. ssp scénarios availables on esgf website.
#' @param level Character. Select column for models name in table input ("source_id" or "institution_id").
#' @param speed_vars Vector. Variable calculed with component.
#' @param compo_vars List of vector. x and y component to calcul variable.
#' 
#' @return List of two binaire tables (models by variables). One with models selected and second with all models before selection.
#'
#' @export NULL

get_models_for_experiment <- function(res_init = res_init, 
                                      experiment, 
                                      level = "source", 
                                      speed_vars = c("sfcWind"), 
                                      compo_vars = list(c("uas", "vas"))) {
    
    #vars_types <- names(res)
    
    sub_experiment <- res_init[res_init$experiment_id == experiment,]

    if(nrow(sub_experiment) == 0){stop(message("Error: Experiment doen't found into table (res)"))}

    sel_var <- switch(level,
                    source = "source_id",
                    institution = "institution_id")
    
    # models X variable (check we have at least one member per variable)
    mods_vars <- ifelse(table(sub_experiment[, sel_var], sub_experiment$variable_id) > 0, 1, 0)

    # select models with all variables (initialisation loop)
    composent <- c(speed_vars, unlist(compo_vars))
    no_composent <- colnames(mods_vars)[!(colnames(mods_vars) %in% composent)]
    models_select <- c()
    boleen_test <- c()

    for(i in 1:nrow(mods_vars)){

      if(all(lapply(no_composent, function(x) mods_vars[i, x] > 0) == rep(TRUE, length(no_composent))) == TRUE){ #if standard variable available for this model check speed and component variables

        boleen_vars <- lapply(speed_vars, function(x) mods_vars[i, x] > 0)
        boleen_compo <- lapply(compo_vars, function(x) mods_vars[i, x] > 0)

        for(z in 1:length(boleen_vars)){ #check available composant or speed variable

          if(boleen_vars[[z]] == TRUE){
            boleen_test <- c(boleen_test, "present")
            } else if(boleen_vars[[z]] == FALSE && all(boleen_compo[[z]] == c(TRUE, TRUE)) == TRUE){
            boleen_test <- c(boleen_test, "present")
            } else{
              boleen_test <- c(boleen_test, "absent")
            }

        }

        if(all(boleen_test == rep("present", length(boleen_vars))) == TRUE){ #if speed variable or component available all TRUE
          models_select <- c(models_select, rownames(mods_vars)[i])
        } # else() speed variable and component aren't available

        boleen_test <- c() #remove test vector

      }# else() standard variables no availables for this model (row i) not select this model

    }

    all_mods <- mods_vars[models_select, ]

    # remove rowname and replace by a new column
    all_mods <- as.data.frame(cbind(rownames(all_mods), all_mods))
    rownames(all_mods) <- NULL
    colnames(all_mods)[1] <- paste0(level, "_id")

    mods_vars <- as.data.frame(cbind(rownames(mods_vars), mods_vars))
    rownames(mods_vars) <- NULL
    colnames(mods_vars)[1] <- paste0(level, "_id")

    return(list(
              select_models = all_mods,
              all_models =  mods_vars))

}

#' select_dataset
#' 
#' @description Select among CMIP6 Datasets (lowest member id & native grid if available). 
#' This fucntion use get_model_for_experiment function to select model availables.
#' 
#' @param res_init Dataframe. Output of cmip_parse_search function (and search_esgf function before) 
#'
#' @return same of export (list)
#' @export two csv files with model selected after filtration and before (all available models)

select_dataset <- function(res_init){

    #res_init <- targets::tar_read("available_dataset_df")

    vars <- targets::tar_read(vars)
    experiments <- targets::tar_read(experiments)

    # selection with get_model_for_experiment() function: check variable available by experiment
    mods_experiments_both <- setNames(lapply(experiments, get_models_for_experiment, res_init = res_init), experiments)
    mods_experiments <- setNames(lapply(experiments, function(x) mods_experiments_both[[x]]$select_models), experiments)

    # export table with all models before selection
    mods_initial <- setNames(lapply(experiments, function(x) mods_experiments_both[[x]]$all_models), experiments)
    mods_initial <- Map(function(x, y) cbind(x, list_name = y), mods_initial, names(mods_initial))
    mods_initial <- do.call(rbind, mods_initial)
    mods_initial_path <- here::here("output", "dataset_found_before_filter.csv")
    write.csv2(mods_initial, file = mods_initial_path, row.names = TRUE)

    # vector of all models
    all_mods <- sort(unique(unlist(lapply(mods_experiments, "[[", "source_id"))))

    message("# filter 1: the following sources have data for all environmental variables (", paste(vars, collapse = ", "), "):\n", paste(all_mods, collapse = ",\n"))

    # prefilter models: what are model available for all experiments? TRUE/FALSE table
    mods_experiments_sum <- sapply(experiments, function(x) setNames(all_mods %in% mods_experiments[[x]][, "source_id"], all_mods))

    # keep only models that implement all scenarios
    mods_experiments_sum_d <- as.data.frame(mods_experiments_sum)
    mods_experiments_filt_scenario <- mods_experiments_sum_d[apply(mods_experiments_sum_d, 1, sum) == length(experiments), ]

    mods_experiments_ok <- rownames(mods_experiments_filt_scenario)
    
    message("# filter 2: the following sources have data for all experiments (", paste(experiments, collapse = ", "), "):\n", paste(mods_experiments_ok, collapse = ",\n"))
    
    message("## selecting the datasets")
    datasets_todown <- lapply(names(mods_experiments_filt_scenario), function(x) {

      message("### experiment: ", x)

      r <-  do.call(c, lapply(mods_experiments_ok, function(mm) {
        #mm = "CESM2-WACCM" mm = "IPSL-CM6A-LR" mm = "MIROC-ES2L" mm = "NorESM2-LM"
        message("#### source model: ", mm)
        
        rrr_d <- subset(res_init, experiment_id == x & source_id == mm)
        
        # rrr <- search_esgf(experiments = x, freq = freq, vars = vars[[vt]],
        #                     mods = mm)
        # rrr_d <- cmip_parse_search(rrr)
        
        #filter members
        memb_vars <- ifelse(table(rrr_d$member_id, rrr_d$variable_id) > 0, 1, 0)
        #memb_vars <- memb_vars[!grepl("i1000", rownames(memb_vars)),]
        membs_ok <- apply(memb_vars, 1, sum) ==  length(vars)
        if (sum(membs_ok) == 0) stop("no members for all vars for ", mm)
        av_members <- stringr::str_sort(rownames(memb_vars)[membs_ok], numeric = TRUE)
        message("##### available members: ", paste(av_members, collapse = ", "))
        filter_member <- grepl(av_members[1], rrr_d$member_id)
        rrr_dd <- rrr_d[filter_member,]
        # if(nrow(rrr_dd) == 0) stop("avail members: ", paste(rrr_d$member_id, collapse = " | "))
        if(nrow(rrr_dd) == length(vars)) {
          message("---> selected dataset: ", unique(rrr_dd$experiment_id),
                  " ", unique(rrr_dd$grid_label),
                  " ", unique(rrr_dd$source_id), " ", unique(rrr_dd$member_id),
                  " for variables: ", paste(sort(rrr_dd$variable_id), collapse = "/"), "\n")
          return(res_init[as.numeric(rownames(rrr_dd)), ])
        }
        
        rrr <- res_init[as.numeric(rownames(rrr_dd)), ]
        rrr_d <- rrr_dd
        
        #grids
        if(length(unique(rrr_d$grid_label)) == 1) {
          message("only one grid available: ", unique(rrr_d$grid_label))
          message("---> selected dataset: ", unique(rrr_dd$experiment_id),
                  " ", unique(rrr_dd$grid_label),
                  " ", unique(rrr_dd$source_id), " ", unique(rrr_dd$member_id),
                  " for variables: ", paste(sort(rrr_dd$variable_id), collapse = "/"), "\n")
          return(rrr)
        }
        if(length(unique(rrr_d$grid_label)) > 1) {
          filter_grid <- rrr_d$grid_label == "gn"
          rrr_dd <- rrr_d[filter_grid, ]
        }
        if(nrow(rrr_dd) != length(vars)) {
          filter_grid <- rrr_d$grid_label == "gr"
          rrr_dd <- rrr_d[filter_grid, ]
        }
        if(nrow(rrr_dd) != length(vars)) {
          filter_grid <- rrr_d$grid_label == "gr1"
          rrr_dd <- rrr_d[filter_grid, ]
        }
        if(nrow(rrr_dd) != length(vars)) stop("avail grids: ", paste(unique(rrr_d$grid_label), collapse = " | "))

        rrr <- res_init[as.numeric(rownames(rrr_dd)), ]
        if (length(rrr) != length(vars)) stop("check me please !")
        message("---> selected dataset: ", unique(rrr_dd$experiment_id),
                " ", unique(rrr_dd$grid_label),
                " ", unique(rrr_dd$source_id), " ", unique(rrr_dd$member_id),
                " for variables: ", paste(sort(rrr_dd$variable_id), collapse = "/"), "\n")
        rrr
      }))

    })

    dat <- data.table::rbindlist(datasets_todown)
    f_out <- here::here("output", "selected_datasets.csv")
    write.csv2(dat, file = f_out, row.names = FALSE)

    return(c(mods_initial_path, f_out))

}

#' download_cmip_data
#'
#' @description Download CMIP data.
#' 
#' @param selected_datasets Dataframe from select_dataset() function with variables selected
#' @param time_span time period downloaded 
#'
#' @return paths of folders into surface layer output netcdf files are downloaded
#' @export variable files (.nc) into folder structure
#'

download_cmip_data <- function( selected_datasets,
                                time_span = targets::tar_load("time_span")){

  message("# Download data files")
  
  selected_datasets <- read.csv2(here::here("output", "selected_datasets.csv"))
  
  res_dir <- "output/data_cmip6"
  dir.create(res_dir, showWarnings = FALSE)
    
  n_datasets <- nrow(selected_datasets)
  
  nc_data <- unlist(lapply(1:n_datasets, function(s) {
    #s = 1
    #get data features
    meta        <- selected_datasets[s, ]
    experiment  <- meta$experiment_id
    var         <- meta$variable_id
    source      <- meta$source_id
    memb        <- meta$member_id
    freq        <- meta$frequency
    grid        <- meta$grid_label
    
    message(paste0("# Dataset ", s, "/", n_datasets, " -> ",
                      source, " - ", experiment, " - ", var))
    
    # make dirs
    source_dir     <- paste0(res_dir, "/", source)
    dir.create(source_dir, showWarnings = FALSE)
    experiment_dir <- paste0(source_dir, "/", experiment)
    dir.create(experiment_dir, showWarnings = FALSE)
    
    #wget bash script
    wgs_f    <- paste0(paste(source, experiment, var, sep = "_"), ".sh")
    wgs_path <- file.path(experiment_dir, wgs_f)
    
    if (file.exists(wgs_path)) {
      message("# Previously downloaded bash script detected: deleting it")
      unlink(wgs_path)
    }
    
    #get the script
    wgs <- search_esgf(experiments = experiment,
                        vars = var,
                        freq = freq,
                        time_span = NULL,
                        sources = source,
                        grids = grid,
                        members = memb,
                        type = "wget",
                        verb = TRUE)
    
    cat(wgs, file = wgs_path)
    Sys.sleep(5)
    Sys.chmod(wgs_path)
        
    message("# Modifying the script to download only files overlapping the project time interval")
    
    #list files to download (as listed in the bash script)
    wgs_content         <- readLines(wgs_path)
    files_to_down_index <- grep("\\.nc", wgs_content)
    files_to_down       <- wgs_content[files_to_down_index]
    files_to_down       <- setNames(gsub("'", "", sapply(files_to_down, function(f) strsplit(f, " ")[[1]][1])), NULL)
    
    if (length(files_to_down) > 1) { #modify bash script for good time interval
      #select by time
      ##files intervals
      splits           <- data.frame(t(data.frame(strsplit(gsub(".nc", "", sapply(strsplit(files_to_down, "_"), "[", 7)), "-"))), stringsAsFactors = FALSE)
      rownames(splits) <- files_to_down
      names(splits)    <- c("start", "end")
      splits$start     <- lubridate::ymd_hms(paste0(splits$start,"01 00:00:00"), tz = "UTC")
      splits$end       <- lubridate::ymd_hms(paste0(splits$end,"12 23:59:59"), tz = "UTC")
      splits$interval  <- lubridate::interval(splits$start, splits$end)
      
      time_span_interval   <- lubridate::interval(lubridate::ymd_hms(time_span$start), lubridate::ymd_hms(time_span$end))
      splits$out_time_span <- !lubridate::int_overlaps(splits$interval, time_span_interval)
      
      elems_to_rem <- files_to_down_index[splits$out_time_span]
      wgs_content  <- wgs_content[-elems_to_rem]
      
      wgs_content[grepl("Script created for",  wgs_content)] <- paste0(wgs_content[grepl("Script created for",  wgs_content)], " and edited programmatically by 'rcmip6' to download ", sum(!splits$out_time_span)," files")
      
      #update script file
      unlink(wgs_path)
      cat(paste(wgs_content, collapse = "\n"), file = wgs_path)
      Sys.sleep(5)
      Sys.chmod(wgs_path)
      
    }
    
    wd <- here::here()
    setwd(experiment_dir)
    wgs_out <- system(paste0("./", wgs_f, " -s"), intern = FALSE)
    
    Sys.sleep(30)
    
    n_retries <- 0
    downloads_all_ok <- FALSE
    
    #check downloads and retry
    while (!downloads_all_ok) {
      wgs_out_report <- system(paste0("./", wgs_f, " -ns"), intern = TRUE)
      files_reports  <- grep("\\.nc", wgs_out_report, value = TRUE)
      reports_ok     <- grepl("Already downloaded and verified", files_reports)
      fail           <- any(!reports_ok)
      failed_files   <- sapply(strsplit(files_reports, " "), "[", 1)[!reports_ok]
      ok_files       <- sapply(strsplit(files_reports, " "), "[", 1)[reports_ok]
      
      if (n_retries > 3) {
        message(paste0("Too many retries (", n_retries, ")\n"))
        message(paste0("Failed files: ", paste(failed_files, collapse = ",\n")))
        return(failed_files) #TODO return a better object
      }
      
      if (fail) {
        n_retries <- n_retries + 1
        message(paste0("Failed files: ", paste(failed_files, collapse = ",\n")))
        wgs_out   <- system(paste0("./", wgs_f, " -s"), intern = FALSE)
      } else {
        message(paste0("Download succes: \n", paste(ok_files, collapse = ",\n")))
        downloads_all_ok <- TRUE
      }
    }
    
    setwd(wd)

  }))

  message("All variables into selected_datasets.csv table downloaded")

  return(list.files(here::here("output", "data_cmip6"), pattern = ".nc$", recursive = TRUE, full.names = TRUE))

}

#' search_and_parse
#'
#' @description Function provisional to check data available into esgf. Not used, remove it?
#'
#'
#' @param Variable Type. Explication.
#' @param Variable Type. Explication.
#'
#' @return Two csv files
#'
#' @export Two tables one with all caracteristics of data availables and one bianire table with models by variables.
#' 

search_and_parse <- function(experiments,
                                freq,
                                vars,
                                time_span = NULL){

    # experiments <- targets::tar_read(experiments)
    # freq <- targets::tar_read(freq)
    # vars <- targets::tar_read(vars)
    # time_span <- targets::tar_read(time_span)

    res <- search_esgf(experiments, freq, vars, time_span)

    tab <- cmip_parse_search(res)
    res_path <- "output/available_dataset.csv"
    write.csv(tab, file = res_path, row.names = FALSE)

    tab_binaire <- select_dataset(res)
    tab_binaire <- Map(function(x, y) cbind(x, list_name = y), tab_binaire, names(tab_binaire))
    tab_binaire <- do.call(rbind, tab_binaire)
    res_path_bin <- "output/available_model_ssp_vars.csv"
    write.csv(tab_binaire, file = res_path_bin, row.names = TRUE)

    return(c(res_path, res_path_bin))
}