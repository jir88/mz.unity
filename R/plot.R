
plotGraph = function(pairs) {
  if (nrow(pairs) > 0) { 
    g = graph.data.frame(pairs, directed = T)
    plot(g, vertex.size = 6, edge.arrow.mode=1, edge.arrow.size = 0.3, vertex.label.cex=.6, vertex.frame.color='lightblue') 
  } else { 
    message("Graph was not plotted, no relations found.") 
  }
}

#' Plot the results of mz-unity.search as a spectrum graph.
#' 
#' \code{unity.specgraph} plots a graph of detected relationships on top of a mass spectrum.
#' 
#' @param df data.frame Columns named "to", "from", "rel". "rel" is used for coloring.
#' @param spec data.frame Columns named "mz", "int".  Rows correspond to vertex indices "to" and "from" in df.
#' @param edgetypes data.frame Defines the colors of each edge rel type. COlumn names "rel", "label", "color"
#' @param speccolor character The color for the spectrum plot
#' @param circlecolor character The color for the circles at the spectrum apexes.
#' 
#' @return A ggplot object contianing the plot.
#' 
#' @seealso See \url{https://github.com/nathaniel-mahieu/mz-unity} for examples. 
#' 
#' @export
#' 
unity.specgraph = function(df, spec, edgetypes, speccolor="black", circlecolor = "forestgreen") {
  
  df$rel = factor(df$rel, levels=edgetypes[,"rel"])
  
  es = as.data.frame(expandGraph(df))
  es$rel = df$rel[es$row]
  es$color = edgetypes[match(as.character(es$rel), edgetypes[,"rel"]), "color"]
  
  vs = data.frame(v=unique(c(unlist(es[,1:2]))))
  vs$x = spec[as.numeric(vs$v),"mz"]
  vs$y = spec[as.numeric(vs$v),"int"]
  
  #spec = subset(spec, id %in% vs$v)
  
  g = igraph::graph_from_data_frame(es, directed = T, vertices = vs)
  l = igraph::layout.auto(g)
  
  df.l = as.data.frame(l)
  df.g = igraph::as_data_frame(g)
  df.g$rel = factor(df.g$rel, levels=edgetypes[,"rel"])
  
  
  df.g$from.x <- df.l$V1[match(df.g$from, as.character(vs$v))]  #  match the from locations from the node data.frame we previously connected
  df.g$from.y <- df.l$V2[match(df.g$from, as.character(vs$v))]
  df.g$to.x <- df.l$V1[match(df.g$to, as.character(vs$v))]  #  match the to locations from the node data.frame we previously connected
  df.g$to.y <- df.l$V2[match(df.g$to, as.character(vs$v))]
  
  ggplot2::ggplot() +
    ggplot2::scale_y_continuous(limits = c(0, max(spec$int)*1.01), expand = c(0,0)) +
    ggplot2::xlab("Mass to Charge Ratio (m/Z)") + ggplot2::ylab("Intensity") + ggplot2::ggtitle("Spectrum Graph") +
    ggplot2::geom_segment(data=df.g, ggplot2::aes(x=from.x,xend = to.x, y=from.y,yend = to.y, colour = rel), size = 0.4) +
    ggplot2::scale_colour_manual(name="Relationship Type", breaks=edgetypes[,"rel"], labels=edgetypes[,"label"], values = edgetypes[,"color"], drop=F) +
    ggplot2::geom_segment(data=spec, mapping=ggplot2::aes(x = mz, xend = mz, y = int, yend = min(int), color=g), color=speccolor, size = 0.6) +
    ggplot2::geom_point(data=df.l, aes(x=V1,y=V2),size=3, colour=circlecolor, shape=1)
}

#' Plot the results of mz-unity.search as a graph.
#' 
#' \code{unity.graph} plots a graph of detected relationships.
#' 
#' @param df data.frame Columns named "to", "from", "rel". "rel" is used for coloring.
#' @param spec data.frame Columns named "mz", "int".  Rows correspond to vertex indices "to" and "from" in df.
#' @param edgetypes data.frame Defines the colors of each edge rel type. COlumn names "rel", "label", "color"
#' @param vcolors character The color for the positive and negative nodes respectively.
#' 
#' @return A ggplot object contianing the plot.
#' 
#' @seealso See \url{https://github.com/nathaniel-mahieu/mz-unity} for examples.
#' 
#' @export
#' 
unity.graph = function(df, spec, edgetypes, vcolors = c("forestgreen", "brown4")) {
  
  df$rel = factor(df$rel, levels=edgetypes[,"rel"])
  isos = subset(df, rel %in% c("isop", "ison"), "A", drop=T)
  
  es = as.data.frame(expandGraph(df))
  es$rel = df$rel[es$row]
  es$color = edgetypes[match(as.character(es$rel), edgetypes[,"rel"]), "color"]
  
  vs = data.frame(v=unique(c(unlist(es[,1:2]))))
  vs$color = vcolors[as.numeric(factor(sign(spec[vs$v,"mz"]), levels = c("1","-1")))]
  vs$color[which(vs$v %in% isos)] = adjustcolor(vcolors[as.numeric(factor(sign(spec[vs$v[which(vs$v %in% isos)],"mz"])))], alpha.f = 0.4)

  es.l = expandGraph(subset(df, g.A == g.B.1))
  g.l = graph.data.frame(es.l, v = vs)
  l = layout.auto(g.l)
    
  g2 = graph.data.frame(es, directed = T, vertices = vs[,c("v", "color"),drop=F])
  plot(g2, asp = .4, vertex.size = 2, edge.arrow.mode=1, edge.arrow.size = 0.3, vertex.label.cex=.6, vertex.frame.color='transparent', vertex.label.color = "transparent", layout=l)
}

#' Custom plotting theme
#' 
#' @param base_size Base font size to use.
#' @importFrom ggplot2 %+replace%
theme_nate <- function(base_size = 16)
{
  ggplot2::theme_grey(base_size = base_size) %+replace%
    ggplot2::theme(
      strip.background = ggplot2::element_rect(colour="grey95"), 
      strip.text = ggplot2::element_text(base_size*0.9, colour="grey40", face="plain"),
      
      panel.background = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour="grey95"),
      panel.grid.minor = ggplot2::element_line(colour="grey99"),
      plot.title = ggplot2::element_text(size = ggplot2::rel(1.2)),
      
      axis.title.y = ggplot2::element_text(vjust=1, angle=90),
      axis.title = ggplot2::element_text(colour="grey40"),
      axis.line = ggplot2::element_line(colour="grey95"),
      axis.ticks = ggplot2::element_line(colour="grey95"),
      
      legend.position="top",
      legend.key = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour="grey40"),
      legend.title  = ggplot2::element_text(colour="grey40", face="bold")
    )
}

ggplot2::theme_set(theme_nate())