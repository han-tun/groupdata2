
#' @importFrom dplyr n
create_num_col_groups <- function(data, n, num_col,
                                  cat_col = NULL, id_col = NULL,
                                  col_name,
                                  id_aggregation_fn = sum,
                                  extreme_pairing_levels = 1,
                                  method = "n_fill",
                                  unequal_method = "first",
                                  optimize_for = "mean",
                                  force_equal = FALSE,
                                  pre_randomize = TRUE) {

  # Most have been checked in parent
  # Check arguments ####
  assert_collection <- checkmate::makeAssertCollection()
  checkmate::assert_string(x = col_name, add = assert_collection)
  checkmate::assert_string(x = unequal_method, add = assert_collection)
  checkmate::assert_string(x = optimize_for, add = assert_collection)
  checkmate::assert_flag(x = pre_randomize, add = assert_collection)
  checkmate::reportAssertions(assert_collection)
  # End of argument checks ####

  # If method is n_*, we are doing folding
  is_n_method <- substring(method, 1, 2) == "n_"

  # Sample data frame before use.
  if (isTRUE(pre_randomize)) {

    # Create unique local temporary index
    local_tmp_index_var <- create_tmp_var(data)
    data[[local_tmp_index_var]] <- seq_len(nrow(data))

    # Reorder randomly
    data <- data %>%
      dplyr::sample_frac(1)
  }

  # Init rank summary for balanced joining of fold ID's
  # when cat_col is specified
  if (isTRUE(is_n_method)) rank_summary <- NULL

  # If cat_col is not NULL
  if (!is.null(cat_col)) {

    # If id_col is not NULL
    if (!is.null(id_col)) {

      # aggregate val col per ID
      ids_aggregated <- data %>%
        dplyr::group_by(!!as.name(cat_col), !!as.name(id_col)) %>%
        dplyr::summarize(aggr_val = id_aggregation_fn(!!as.name(num_col))) %>%
        dplyr::ungroup()

      # Find groups for each category
      ids_grouped <- plyr::ldply(unique(ids_aggregated[[cat_col]]), function(category) {
        ids_for_cat <- ids_aggregated[
          ids_aggregated[[cat_col]] == category,
        ]
        ids_for_cat$._new_groups_ <-
          numerically_balanced_group_factor_(
            ids_for_cat,
            n = n,
            num_col = "aggr_val",
            method = method,
            unequal_method = unequal_method,
            extreme_pairing_levels = extreme_pairing_levels
          )

        if (isTRUE(is_n_method)) {
          # Rename groups to be combined in the most balanced way
          if (is.null(rank_summary)) {
            rank_summary <<- create_rank_summary(
              ids_for_cat,
              levels_col = "._new_groups_",
              num_col = "aggr_val"
            )
          } else {
            renaming_levels_list <- rename_levels_by_reverse_rank_summary(
              data = ids_for_cat,
              rank_summary = rank_summary,
              levels_col = "._new_groups_",
              num_col = "aggr_val"
            )
            rank_summary <<-
              renaming_levels_list[["updated_rank_summary"]]
            ids_for_cat <- renaming_levels_list[["updated_data"]]
          }
        }

        ids_for_cat %>%
          base_deselect(cols = "aggr_val")
      })

      # Transfer groups to data
      data <- data %>%
        dplyr::inner_join(ids_grouped, by = c(cat_col, id_col))

      # If id_col is NULL
    } else {

      # For each category in cat_col
      # .. create value balanced group factor

      # Find groups for each category
      data <- plyr::ldply(unique(data[[cat_col]]), function(category) {
        data_for_cat <- data[
          data[[cat_col]] == category,
        ]
        data_for_cat$._new_groups_ <- numerically_balanced_group_factor_(
          data = data_for_cat,
          n = n,
          num_col = num_col,
          method = method,
          unequal_method = unequal_method,
          extreme_pairing_levels = extreme_pairing_levels
        )

        if (isTRUE(is_n_method)) {
          # Rename groups to be combined in the most balanced way
          if (is.null(rank_summary)) {
            rank_summary <<- create_rank_summary(
              data_for_cat,
              levels_col = "._new_groups_",
              num_col = num_col
            )
          } else {
            renaming_levels_list <- rename_levels_by_reverse_rank_summary(
              data = data_for_cat, rank_summary = rank_summary,
              levels_col = "._new_groups_", num_col = num_col
            )
            rank_summary <<- renaming_levels_list[["updated_rank_summary"]]
            data_for_cat <- renaming_levels_list[["updated_data"]]
          }
        }

        data_for_cat
      })
    }

    # If cat_col is NULL
  } else {

    # If id_col is not NULL
    if (!is.null(id_col)) {

      # Aggregate num_col for IDs with the passed id_aggregation_fn
      # Create value balanced group factor based on aggregated values
      # Join the groups back into the data

      # aggregate val col per ID
      ids_aggregated <- data %>%
        group_by(!!as.name(id_col)) %>%
        dplyr::summarize(aggr_val = id_aggregation_fn(!!as.name(num_col))) %>%
        dplyr::ungroup()

      # Create group factor
      ids_aggregated$._new_groups_ <- numerically_balanced_group_factor_(
        ids_aggregated,
        n = n,
        num_col = "aggr_val",
        method = method,
        unequal_method = unequal_method,
        extreme_pairing_levels = extreme_pairing_levels
      )
      ids_aggregated$aggr_val <- NULL

      # Transfer groups to data
      data <- data %>%
        dplyr::inner_join(ids_aggregated, by = c(id_col))

      # If id_col is NULL
    } else {

      # Add group factor
      data$._new_groups_ <- numerically_balanced_group_factor_(
        data,
        n = n,
        num_col = num_col,
        method = method,
        unequal_method = unequal_method,
        extreme_pairing_levels = extreme_pairing_levels
      )
    }
  }

  # Reorder if pre-randomized
  if (isTRUE(pre_randomize)) {
    data <- data %>%
      dplyr::arrange(!!as.name(local_tmp_index_var))
    data[[local_tmp_index_var]] <- NULL
  }

  # Force equal
  # Remove stuff
  if (method == "l_sizes" & isTRUE(force_equal)) {
    number_of_groups_specified <- length(n)

    data <- data[
      factor_to_num(data[["._new_groups_"]]) <= number_of_groups_specified,
    ]
  }

  # replace column name
  if (col_name != "._new_groups_")
    data <- base_rename(data, before = "._new_groups_", after = col_name)

  dplyr::as_tibble(data)
}
