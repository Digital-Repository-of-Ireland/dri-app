### Example queries

```graphql
query getAllPublishedCollections {
  allCollections {
    id, publishedAt, createDate, modifiedDate,
    
    title, creator,
    
    depositingInstitute,
    
    licence, language, contributor, publishedDate, relation, 
    coverage, temporalCoverage, geographicalCoverage, subject,
    qdcId
  }
}


query getAllPublishedObjects {
  allObjects {
    id
  }
}

query getSecondAndThirdCollection {
  allCollections(first:2) {
    id
  }
}

query getTestDescription {
  allCollections(filter:{descriptionContains:"real"}) {
    id, description
  }
}
```
