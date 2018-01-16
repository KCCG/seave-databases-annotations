# Usage:
# Rscript --vanilla parse_raw_orphanet.R

# Code courtesy of Mark Pinese with modification by Vel

library(XML)

# Function to parse the output from Orphanet for rare diseases with their associated genes
flattenDisorder2Gene = function(disorder2gene) {
  disorder2gene_flat.disorder_id = c()
  disorder2gene_flat.disorder_on = c()
  disorder2gene_flat.disorder_name = c()
  disorder2gene_flat.gene_on = c()
  disorder2gene_flat.gene_symbol = c()
  disorder2gene_flat.assoc_type = c()
  disorder2gene_flat.assoc_status = c()
  
  for (i in 1:length(disorder2gene$children[[1]][[1]])) {
    if (disorder2gene$children[[1]][[1]][[i]]$name != "Disorder")
      next
    
    disorder_id = disorder2gene$children[[1]][[1]][[i]]$attributes[["id"]]
    disorder_on = disorder2gene$children[[1]][[1]][[i]]$children$OrphaNumber$children$text$value
    disorder_name = disorder2gene$children[[1]][[1]][[i]]$children$Name$children$text$value
    genelist = disorder2gene$children[[1]][[1]][[i]]$children$DisorderGeneAssociationList
    
    for (j in 1:length(genelist)) {
      gene_on = genelist[[j]]$children$Gene$children$OrphaNumber$children$text$value
      gene_symbol = genelist[[j]]$children$Gene$children$Symbol$children$text$value
      gene_assoc_type = genelist[[j]]$children$DisorderGeneAssociationType$children$Name$children$text$value
      gene_assoc_status = genelist[[j]]$children$DisorderGeneAssociationStatus$children$Name$children$text$value
      
      disorder2gene_flat.disorder_id = c(disorder2gene_flat.disorder_id, disorder_id)
      disorder2gene_flat.disorder_on = c(disorder2gene_flat.disorder_on, disorder_on)
      disorder2gene_flat.disorder_name = c(disorder2gene_flat.disorder_name, disorder_name)
      disorder2gene_flat.gene_on = c(disorder2gene_flat.gene_on, gene_on)
      disorder2gene_flat.gene_symbol = c(disorder2gene_flat.gene_symbol, gene_symbol)
      disorder2gene_flat.assoc_type = c(disorder2gene_flat.assoc_type, gene_assoc_type)
      disorder2gene_flat.assoc_status = c(disorder2gene_flat.assoc_status, gene_assoc_status)
    }
  }
  
  disorder2gene_flat = data.frame(
    disorder_id = as.integer(as.character(disorder2gene_flat.disorder_id)),
    disorder_on = as.integer(as.character(disorder2gene_flat.disorder_on)),
    disorder_name = disorder2gene_flat.disorder_name,
    gene_symbol = disorder2gene_flat.gene_symbol,
    gene_on = as.integer(as.character(disorder2gene_flat.gene_on)),
    assoc_type = disorder2gene_flat.assoc_type,
    assoc_status = disorder2gene_flat.assoc_status
  )
  
  disorder2gene_flat
}

# Function to parse the output from Orphanet for rare diseases epidemiological data (prevalance)
flattenDisorder2Prevalence = function(disorder2prevalence) {
  disorder2prevalence_flat.disorder_on = c()
  disorder2prevalence_flat.prevalence_type = c()
  disorder2prevalence_flat.prevalence_class = c()
  disorder2prevalence_flat.prevalence_qualification = c()
  disorder2prevalence_flat.prevalence_valmoy = c()
  disorder2prevalence_flat.prevalence_geographic = c()
  disorder2prevalence_flat.prevalence_status = c()
  
  for (i in 1:length(disorder2prevalence$children[[1]][[1]])) {
    disorder_on = disorder2prevalence$children[[1]][[1]][[i]]$children$OrphaNumber$children$text$value
    nprev = length(disorder2prevalence$children[[1]][[1]][[i]]$children$PrevalenceList)
    
    if (nprev == 0)
      next
    
    for (j in 1:nprev) {
      prevalence_type = disorder2prevalence$children[[1]][[1]][[i]]$children$PrevalenceList[[j]]$children$PrevalenceType$children$Name$children$text$value
      prevalence_class = disorder2prevalence$children[[1]][[1]][[i]]$children$PrevalenceList[[j]]$children$PrevalenceClass$children$Name$children$text$value
      if (is.null(prevalence_class))
        prevalence_class = NA
      prevalence_qual = disorder2prevalence$children[[1]][[1]][[i]]$children$PrevalenceList[[j]]$children$PrevalenceQualification$children$Name$children$text$value
      prevalence_valmoy = disorder2prevalence$children[[1]][[1]][[i]]$children$PrevalenceList[[j]]$children$ValMoy$children$text$value
      prevalence_geographic = disorder2prevalence$children[[1]][[1]][[i]]$children$PrevalenceList[[j]]$children$PrevalenceGeographic$children$Name$children$text$value
      prevalence_status = disorder2prevalence$children[[1]][[1]][[i]]$children$PrevalenceList[[j]]$children$PrevalenceValidationStatus$children$Name$children$text$value
      
      disorder2prevalence_flat.disorder_on = c(disorder2prevalence_flat.disorder_on, disorder_on)
      disorder2prevalence_flat.prevalence_type = c(disorder2prevalence_flat.prevalence_type, prevalence_type)
      disorder2prevalence_flat.prevalence_class = c(disorder2prevalence_flat.prevalence_class, prevalence_class)
      disorder2prevalence_flat.prevalence_qualification = c(disorder2prevalence_flat.prevalence_qualification, prevalence_qual)
      disorder2prevalence_flat.prevalence_valmoy = c(disorder2prevalence_flat.prevalence_valmoy, prevalence_valmoy)
      disorder2prevalence_flat.prevalence_geographic = c(disorder2prevalence_flat.prevalence_geographic, prevalence_geographic)
      disorder2prevalence_flat.prevalence_status = c(disorder2prevalence_flat.prevalence_status, prevalence_status)
    }
  }
  
  disorder2prevalence_flat = data.frame(
    disorder_on = as.integer(as.character(disorder2prevalence_flat.disorder_on)),
    prevalence_type = disorder2prevalence_flat.prevalence_type,
    prevalence_class = disorder2prevalence_flat.prevalence_class,
    prevalence_qualification = disorder2prevalence_flat.prevalence_qualification,
    prevalence_valmoy = disorder2prevalence_flat.prevalence_valmoy,
    prevalence_geographic = disorder2prevalence_flat.prevalence_geographic,
    prevalence_status = disorder2prevalence_flat.prevalence_status
  )
  
  disorder2prevalence_flat
}

# Function to parse the output from Orphanet for rare diseases epidemiological data (ages - ages of onset)
flattenDisorder2Age = function(disorder2age) {
  disorder2age_flat.disorder_on = c()
  disorder2age_flat.age_of_onset = c()
  
  for (i in 1:length(disorder2age$children[[1]][[1]])) {
    disorder_on = disorder2age$children[[1]][[1]][[i]]$children$OrphaNumber$children$text$value
    nonset = length(disorder2age$children[[1]][[1]][[i]]$children$AverageAgeOfOnsetList)
    
    if (nonset == 0)
      next
    
    for (j in 1:nonset) {
      onset = disorder2age$children[[1]][[1]][[i]]$children$AverageAgeOfOnsetList[[j]]$children$Name$children$text$value
      
      disorder2age_flat.disorder_on = c(disorder2age_flat.disorder_on, disorder_on)
      disorder2age_flat.age_of_onset = c(disorder2age_flat.age_of_onset, onset)
    }
  }
  
  disorder2age_flat = data.frame(
    disorder_on = as.integer(as.character(disorder2age_flat.disorder_on)),
    age_of_onset = disorder2age_flat.age_of_onset
  )
  
  disorder2age_flat
}

# Function to parse the output from Orphanet for rare diseases epidemiological data (ages - inheritance)
flattenDisorder2Inheritance = function(disorder2inheritance) {
  disorder2inheritance_flat.disorder_on = c()
  disorder2inheritance_flat.inheritance = c()
  
  for (i in 1:length(disorder2inheritance$children[[1]][[1]])) {
    disorder_on = disorder2inheritance$children[[1]][[1]][[i]]$children$OrphaNumber$children$text$value
    ninheritance = length(disorder2inheritance$children[[1]][[1]][[i]]$children$TypeOfInheritanceList)
    
    if (ninheritance == 0)
      next
    
    for (j in 1:ninheritance) {
      inheritance = disorder2inheritance$children[[1]][[1]][[i]]$children$TypeOfInheritanceList[[j]]$children$Name$children$text$value
      
      disorder2inheritance_flat.disorder_on = c(disorder2inheritance_flat.disorder_on, disorder_on)
      disorder2inheritance_flat.inheritance = c(disorder2inheritance_flat.inheritance, inheritance)
    }
  }
  
  disorder2inheritance_flat = data.frame(
    disorder_on = as.integer(as.character(disorder2inheritance_flat.disorder_on)),
    inheritance = disorder2inheritance_flat.inheritance
  )
  
  disorder2inheritance_flat
}

# Parse the rare diseases with their associated genes Orphanet output
disorder2gene = xmlTreeParse("/Users/velimir/Downloads/en_product6.xml", getDTD = FALSE)
disorder2gene_flat = flattenDisorder2Gene(disorder2gene)
rm(disorder2gene, flattenDisorder2Gene)
gc()

# Parse the rare diseases epidemiological data (prevalance) Orphanet output
#disorder2prevalence = xmlTreeParse("/Users/velimir/Downloads/en_product2_prev.xml", getDTD = FALSE)
#disorder2prevalence_flat = flattenDisorder2Prevalence(disorder2prevalence)
#rm(disorder2prevalence, flattenDisorder2Prevalence)
#gc()
# Vel: NOT USED CURRENTLY

# Parse the rare diseases epidemiological data (ages - ages of onset) Orphanet output
disorder2age = xmlTreeParse("/Users/velimir/Downloads/en_product2_ages.xml", getDTD = FALSE)
disorder2age_flat = flattenDisorder2Age(disorder2age)
rm(disorder2age, flattenDisorder2Age)
gc()

# Parse the rare diseases epidemiological data (ages - inheritance) Orphanet output
disorder2inheritance = xmlTreeParse("/Users/velimir/Downloads/en_product2_ages.xml", getDTD = FALSE)
disorder2inheritance_flat = flattenDisorder2Inheritance(disorder2inheritance)
rm(disorder2inheritance, flattenDisorder2Inheritance)
gc()

# Plot the number of genes associated with x disorders
#hist(table(disorder2gene_flat$gene_symbol))
#table(table(disorder2gene_flat$gene_symbol))

write.table(disorder2gene_flat, "~/Desktop/disorder2gene.tsv", sep="\t", quote=FALSE)
#write.table(disorder2prevalence_flat, "~/Desktop/disorder2prevalence.tsv", sep="\t", quote=FALSE)
write.table(disorder2inheritance_flat, "~/Desktop/disorder2inheritance.tsv", sep="\t", quote=FALSE)
write.table(disorder2age_flat, "~/Desktop/disorder2age.tsv", sep="\t", quote=FALSE)

#merged = merge(merge(disorder2gene_flat, disorder2prevalence_flat, all.x = TRUE, all.y = FALSE, by = "disorder_on"), disorder2category_flat, all.x = TRUE, all.y = FALSE, by = "disorder_on")


#merged$prevalence_class = ordered(as.vector(merged$prevalence_class), levels = c("<1 / 1 000 000", "1-9 / 1 000 000", "1-9 / 100 000", "1-5 / 10 000", "6-9 / 10 000", ">1 / 1000", "Not yet documented", "Unknown" ))
#boxplot(log10(as.numeric(as.character(as.vector(prevalence_valmoy)))) ~ prevalence_class, merged)
#abline(-2.5, 1)


#saveRDS(merged, file = "14_orphadata_gene_merged.rds")