% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sampling.R
\name{upsample}
\alias{upsample}
\title{Upsampling of rows in a dataframe.}
\usage{
upsample(data, cat_col, id_col = NULL, id_method = "n_ids",
  mark_new_rows = FALSE, new_rows_col_name = ".new_row")
}
\arguments{
\item{data}{Dataframe.}

\item{cat_col}{Name of categorical variable to balance by. (Character)}

\item{id_col}{Name of factor with IDs. (Character)

 IDs are considered entities, e.g. allowing us to add or remove all rows for an ID.
 How this is used is up to the \code{id_method}.

 E.g. If we have measured a participant multiple times and
 want make sure that we keep all these measurements. Then we would either
 remove/add all measurements for the participant or leave in
 all measurements for the participant.}

\item{id_method}{Method for balancing the IDs. (Character)

 \code{n_ids}, \code{n_rows_c}, \code{distributed}, or \code{nested}.
 \subsection{n_ids}{
 Balances on ID level only. It makes sure there are the same number of IDs for each category.
 This might lead to a different number of rows between categories.
 }
 \subsection{n_rows_c}{
 Attempts to level the number of rows per category, while only removing/adding entire IDs.
 This is done in 2 steps:
 \enumerate{
 \item If a category needs to add all its rows one or more times, the data is repeated.
 \item Iteratively, the ID with the number of rows closest to the
    lacking/excessive number of rows is added/removed.
    This happens until adding/removing the closest ID would lead to a size further from
    the target size than the current size.
    If multiple IDs are closest, one is randomly sampled.
    }
 }
 \subsection{distributed}{
 Distributes the lacking/excess rows equally between the IDs.
 If the number to distribute can not be equally divided, some IDs will have 1 row more/less than the others.
 }
 \subsection{nested}{
 Calls balance() on each category with IDs as cat_col.

 I.e. if size is "min", IDs will have the size of the smallest ID in their category.
 }}

\item{mark_new_rows}{Add column with 1s for added rows, and 0s for original rows. (Logical)}

\item{new_rows_col_name}{Name of column marking new rows. Defaults to ".new_row".}
}
\value{
Dataframe with added rows. Ordered by cat_col and (potentially) id_col.
}
\description{
Uses random upsampling to fix the group sizes to the
 largest group in the data frame.

 Wraps \code{\link{balance}()}.
}
\details{
\subsection{Without id_col}{
Upsampling is done with replacement for added rows, while the original data remains intact.}
\subsection{With id_col}{See id_method description.}
}
\examples{
# Attach packages
library(groupdata2)

# Create dataframe
df <- data.frame(
  "participant" = factor(c(1, 1, 2, 3, 3, 3, 3, 4, 4, 5, 5, 5, 5)),
  "diagnosis" = factor(c(0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0)),
  "trial" = c(1, 2, 1, 1, 2, 3, 4, 1, 2, 1, 2, 3, 4),
  "score" = sample(c(1:100), 13)
)

# Using upsample()
upsample(df, cat_col="diagnosis")

# Using upsample() with id_method "n_ids"
# With column specifying added rows
upsample(df, cat_col="diagnosis",
        id_col="participant", id_method="n_ids",
        mark_new_rows = TRUE)

# Using upsample() with id_method "n_rows_c"
# With column specifying added rows
upsample(df, cat_col="diagnosis",
        id_col="participant", id_method="n_rows_c",
        mark_new_rows = TRUE)

# Using upsample() with id_method "distributed"
# With column specifying added rows
upsample(df, cat_col="diagnosis",
        id_col="participant", id_method="distributed",
        mark_new_rows = TRUE)

# Using upsample() with id_method "nested"
# With column specifying added rows
upsample(df, cat_col="diagnosis",
        id_col="participant", id_method="nested",
        mark_new_rows = TRUE)
}
\seealso{
Other sampling functions: \code{\link{balance}},
  \code{\link{downsample}}
}
\author{
Ludvig Renbo Olsen, \email{r-pkgs@ludvigolsen.dk}
}
\concept{sampling functions}