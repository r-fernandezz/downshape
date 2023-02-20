#' Construct an url to query the api at https://esgf-node.llnl.gov
#'
#' @param experiments (character) the desired experiments
#' @param freq (character) the desired temporal frequency
#' @param vars (character) the desired variable ids
#' @param sources (character) the desired models (sources) ids (may be NULL)
#' @param grids (character) the desired kind(s) of grid
#' @param type (character) "search" to query esgf for availaible data info, "wget" to download a bash script
#' @param limit (character) the maximum number of results to return
#'
#' @return (character) a json query to run over https://esgf-node.llnl.gov
#' @export

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


#' Query https://esgf-node.llnl.gov 
#'
#' @param url a formated http query url
#' @param show_url print the query url ?
#' @param type
#' @param verb (bolean) should the funciton be verbose ?
#'
#' @return a parsed json list
#' @export

query_esgf <- function(url,
                        type ="search",
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


#' Construct urls and query over https://esgf-node.llnl.gov
#'
#' @param experiments (character) the desired experiments
#' @param freq (character) the desired temporal frequency
#' @param vars (character) the desired variable ids
#' @param mods (character) the desired models (sources) ids (may be NULL)
#' @param grids (character) the desired kind(s) of grid
#' @param members (character) the desired member(s)
#' @param type (character) "search" to query esgf for availaible data info, "wget" to download a bash script
#' @param limit (character) the maximum number of results to return
#' @param verb (bolean) should the funciton be verbose ?
#'
#' @return a parsed json list
#' @export

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

#' Parse an ESGF json result as a data.frame
#'
#' @param results an ESGF json result
#'
#' @return a data.frame
#' @export

cmip_parse_search <- function(results) {

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


#' Select among CMIP6 Datasets (lowest member id & native grid if available)
#'
#' @param res_init 
#'
#' @return
#' @export

select_datasets <- function(res_init) {

    #res_init <- targets::tar_read("cmip6_datasets")

    vars <- attr(res_init, "vars")
    experiments <- attr(res_init, "experiments")

    res <- cmip_parse_search(res_init)

    # models X experiments  
    get_models_for_experiment <- function(res, experiment = "historical", level = "source") {
        
        #vars_types <- names(res)
        
        sub_experiment <- res[res$experiment_id == experiment,]
        
        sel_var <- switch(level,
                        source = "source_id",
                        institution = "institution_id")
        
        # models X variable (check we have at least one member per variable)
        mods_vars <- ifelse(table(sub_experiment[, sel_var], sub_experiment$variable_id) > 0, 1, 0)
        # models with all vars
        all_mods <- rownames(mods_vars[apply(mods_vars, 1, sum) == length(vars), ])
        d <- data.frame(model = all_mods, stringsAsFactors = FALSE)
        # d[, vars_types[1]] <- is.element(d$model, all_vars_mods[[vars_types[1]]])
        # if (length(vars_types) > 1) for (i in vars_types[-1]) d[, i] <- is.element(d$model, all_vars_mods[[i]])
        d[, experiment] <- TRUE
        names(d)[1] <- paste0(level, "_id")
        d
        
    }

    # # scenario-list of type of variable availability
    mods_experiments <- setNames(lapply(experiments, get_models_for_experiment, res = res), experiments)

    # # vector of all models
    all_mods <- sort(unique(unlist(lapply(mods_experiments, "[[", "source_id"))))

    # #choose data provenance (os or d3)
    # # mods_experiments <- lapply(mods_experiments, function(x) {
    # #   xy <- cbind(x[, 2], x[,3] * 2)
    # #   choice <- ifelse(apply(xy, 1, sum) %in% c(1, 3), names(x)[2], names(x)[3] ) 
    # #   data.frame(x, var_type = choice, stringsAsFactors = FALSE)[, -c(2,3)]
    # # })

    # # prefilter models
    mods_experiments_sum <- sapply(mods_experiments, function(x) setNames(all_mods %in% x[, "source_id"], all_mods))

    return(mods_experiments_sum)

    # # remove models with less than 'min_scen_num' or less scenario
    # #min_scen_num <- 4 #TODO this is fixed !
    # #mods_experiments_filt_scenario <- mods_experiments_sum[apply(mods_experiments_sum, 1, sum) >= min_scen_num, ]

    # # keep only models that implement ssp534-over
    # #mods_experiments_filt_scenario <- data.frame(mods_experiments_sum[mods_experiments_sum[,"ssp534-over"], ], check.names = FALSE)

    # # keep only models that implement all scenarios
    # mods_experiments_filt_scenario <- data.frame(mods_experiments_sum[apply(mods_experiments_sum, 1, sum) == length(experiments), ], check.names = FALSE)

    # # remove c("CanESM5-CanOE", "CESM2")  
    # # mods_experiments_filt_institution <- mods_experiments_filt_scenario[!(rownames(mods_experiments_filt_scenario) %in% c("CanESM5-CanOE", "CESM2")), ]
    # # mods_experiments_ok <- rownames(mods_experiments_filt_institution)
    
    # mods_experiments_ok <- rownames(mods_experiments_filt_scenario)
    
    # message("# the following sources have data for all experiments (", paste(experiments, collapse = ", "), "):\n", paste(mods_experiments_ok, collapse = ",\n"))
    
    # message("## selecting the datasets")
    # datasets_todown <- lapply(names(mods_experiments_filt_scenario), function(x) {
    #   #x  = "historical" ; x = "ssp534-over"
    #   message("### experiment: ", x)
    #   # d <- mods_experiments[[x]]
    #   # d <- d[d[, "source_id"] %in% mods_experiments_ok, ]
    #   r <-  do.call(c, lapply(mods_experiments_ok, function(mm) {
    #     #mm = "CESM2-WACCM" mm = "IPSL-CM6A-LR" mm = "MIROC-ES2L" mm = "NorESM2-LM"
    #     message("#### source model: ", mm)
        
    #     rrr_d <- subset(res, experiment_id == x & source_id == mm)
        
    #     # rrr <- search_esgf(experiments = x, freq = freq, vars = vars[[vt]],
    #     #                     mods = mm)
    #     # rrr_d <- cmip_parse_search(rrr)
        
    #     #filter members
    #     memb_vars <- ifelse(table(rrr_d$member_id, rrr_d$variable_id) > 0, 1, 0)
    #     #memb_vars <- memb_vars[!grepl("i1000", rownames(memb_vars)),]
    #     membs_ok <- apply(memb_vars, 1, sum) ==  length(vars)
    #     if (sum(membs_ok) == 0) stop("no members for all vars for ", mm)
    #     av_members <- stringr::str_sort(rownames(memb_vars)[membs_ok], numeric = TRUE)
    #     message("##### available members: ", paste(av_members, collapse = ", "))
    #     filter_member <- grepl(av_members[1], rrr_d$member_id)
    #     rrr_dd <- rrr_d[filter_member,]
    #     # if(nrow(rrr_dd) == 0) stop("avail members: ", paste(rrr_d$member_id, collapse = " | "))
    #     if(nrow(rrr_dd) == length(vars)) {
    #       message("---> selected dataset: ", unique(rrr_dd$experiment_id),
    #               " ", unique(rrr_dd$grid_label),
    #               " ", unique(rrr_dd$source_id), " ", unique(rrr_dd$member_id),
    #               " for variables: ", paste(sort(rrr_dd$variable_id), collapse = "/"), "\n")
    #       return(res_init[as.numeric(rownames(rrr_dd))])
    #     }
        
    #     rrr <- res_init[as.numeric(rownames(rrr_dd))]
    #     rrr_d <- rrr_dd
        
    #     #grids
    #     if(length(unique(rrr_d$grid_label)) == 1) {
    #       message("only one grid available: ", unique(rrr_d$grid_label))
    #       message("---> selected dataset: ", unique(rrr_dd$experiment_id),
    #               " ", unique(rrr_dd$grid_label),
    #               " ", unique(rrr_dd$source_id), " ", unique(rrr_dd$member_id),
    #               " for variables: ", paste(sort(rrr_dd$variable_id), collapse = "/"), "\n")
    #       return(rrr)
    #     }
    #     if(length(unique(rrr_d$grid_label)) > 1) {
    #       filter_grid <- rrr_d$grid_label == "gn"
    #       rrr_dd <- rrr_d[filter_grid, ]
    #     }
    #     if(nrow(rrr_dd) != length(vars)) {
    #       filter_grid <- rrr_d$grid_label == "gr"
    #       rrr_dd <- rrr_d[filter_grid, ]
    #     }
    #     if(nrow(rrr_dd) != length(vars)) {
    #       filter_grid <- rrr_d$grid_label == "gr1"
    #       rrr_dd <- rrr_d[filter_grid, ]
    #     }
    #     if(nrow(rrr_dd) != length(vars)) stop("avail grids: ", paste(unique(rrr_d$grid_label), collapse = " | "))

    #     rrr <- res_init[as.numeric(rownames(rrr_dd))]
    #     if (length(rrr) != length(vars)) stop("check me please !")
    #     message("---> selected dataset: ", unique(rrr_dd$experiment_id),
    #             " ", unique(rrr_dd$grid_label),
    #             " ", unique(rrr_dd$source_id), " ", unique(rrr_dd$member_id),
    #             " for variables: ", paste(sort(rrr_dd$variable_id), collapse = "/"), "\n")
    #     rrr
    #   }))
    # })
      
    # datasets_todown <- do.call(c, datasets_todown)
    # #attributes(datasets_todown) <- attributes(res_init)
    # #datasets_todown
    
    # dat <- cmip_parse_search(datasets_todown)
    # f_out <- "outputs/selected_datasets.csv"
    # write.csv(dat, file = f_out, row.names = FALSE)
    # f_out
}

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
    write.csv(tab, file = "outputs/available_dataset.csv", row.names = FALSE)

    tab_binaire <- select_datasets(res)
    write.csv(tab_binaire, file = "outputs/available_model_ssp.csv", row.names = TRUE)

    return(c(
        here::here("outputs", "selected_dataset.csv")
    ))
}