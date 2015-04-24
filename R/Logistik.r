Logistik<-function (data, member, member.type="group",match="score", anchor = 1:ncol(data), type = "both", 
    criterion = "LRT") 
{
    R2 <- function(m, n) 1 - (exp(-m$null.deviance/2 + m$deviance/2))^(2/n)
    R2max <- function(m, n) 1 - (exp(-m$null.deviance/2))^(2/n)
    R2DIF <- function(m, n) R2(m, n)/R2max(m, n)
    dev <- R2full<-R2simple<-deltaR <- NULL
    mFull <- mSimple <- matrix(0, ncol(data), 4)
    if (member.type=="group") GROUP<-as.factor(member)
else GROUP<-member
    for (item in 1:ncol(data)) {
if (match[1]=="score"){
        data2 <- data[, anchor]
        if (sum(anchor == item) == 0) 
            data2 <- cbind(data2, data[, item])
        SCORES <- rowSums(data2, na.rm = TRUE)
      }
else SCORES<-match
	  ITEM<-data[,item]
        m0 <- switch(type, both = glm(ITEM ~SCORES * GROUP, family = "binomial"),
            udif = glm(ITEM ~ SCORES + GROUP, family = "binomial"), 
            nudif = glm(ITEM ~ SCORES * GROUP, family = "binomial"))
        m1 <- switch(type, both = glm(ITEM ~ SCORES, family = "binomial"),
            udif = glm(ITEM ~ SCORES, family = "binomial"), 
            nudif = glm(ITEM ~ SCORES + GROUP, family = "binomial"))
        if (criterion == "LRT") 
            dev[item] <- deviance(m1) - deviance(m0)
        else {
            if (criterion != "Wald") 
                stop("'criterion' must be either 'LRT' or Wald'", 
                  call. = FALSE)
            else {
                coeff <- as.numeric(coefficients(m0))
                covMat <- summary(m0)$cov.scaled
                if (type == "udif") 
                  C <- rbind(c(0, 0, 1))
                else {
                  if (type == "nudif") 
                    C <- rbind(c(0, 0, 0, 1))
                  else C <- rbind(c(0, 0, 1, 0), c(0, 0, 0, 1))
                }
                dev[item] <- t(C %*% coeff) %*% solve(C %*% covMat %*% 
                  t(C)) %*% C %*% coeff
            }
        }
        R2full[item] <- R2DIF(m0, nrow(data)) 
        R2simple[item] <- R2DIF(m1, nrow(data)) 
        deltaR[item] <- R2DIF(m0, nrow(data)) - R2DIF(m1, nrow(data))
        mFull[item, 1:length(m0$coefficients)] <- m0$coefficients
        mSimple[item, 1:length(m1$coefficients)] <- m1$coefficients
    }
    colnames(mFull) <- colnames(mSimple) <- c("(Intercept)", 
        "SCORE", "GROUP", "SCORE:GROUP")
    res <- list(stat = dev, R2M0=R2full,R2M1=R2simple, deltaR2 = deltaR, parM0 = mFull, 
        parM1 = mSimple, criterion = criterion,member.type=member.type,
match=ifelse(match[1]=="score","score","matching variable"))
    return(res)
}
