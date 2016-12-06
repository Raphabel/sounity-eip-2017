//
//  RoutesAPISoundcloud.swift
//  Sounity
//
//  Created by Degraeve Raphaël on 07/07/2016.
//  Copyright © 2016 Degraeve Raphaël. All rights reserved.
//

enum SouncloudAPIRoutes: String {
    case SEARCHBOX = "https://api-v2.soundcloud.com/search/autocomplete?queries_limit=0&results_limit=20&limit=2&offset=0&linked_partitioning=1"
    case TRACK = "https://api.soundcloud.com/tracks/"
    case CLIENT_ID = "14865c40300d54f2e25d7beddb36def7"
}

/*
 
 ** ROUTES SEARCH API V2
 
 Cette route prend plusieurs paramètres qui sont
 
 - q: qui représente la string que l'on utilise pour la recherche
 - queries_limit:
 - results_limit: qui permet de limiter les résultat
 - limit:
 - linked_partitioning:
 **
 
 */