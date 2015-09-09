package com.test

import org.apache.spark.sql.SQLContext
import org.apache.spark.{SparkContext, SparkConf}
import org.elasticsearch.spark.rdd.EsSpark

import java.util.{Calendar, UUID, Date}
import java.io.File
import java.net.URL
import sys.process._

case class Oink(id: String, content: String, created_at: java.util.Date, handle: String)

object ShakespeareIngest {

  def main(args: Array[String]): Unit = {
    val conf = new SparkConf(true)
      .set("es.nodes", args.lift(0).getOrElse("localhost"))
      .set("es.index.auto.create", "true")

    val sc = new SparkContext("local", "Shakespeare Ingest", conf)

    val url = args.lift(1)
      .getOrElse("http://s3.amazonaws.com/downloads.mesosphere.io/dcos-demo/spark/shakespeare_data.json")
    if (url.startsWith("http")) {
      new URL(url) #> new File("/tmp/shakespeare_data.json") !!
    }

    val shakespeare = new SQLContext(sc) //creating a Row RDD from JSON file. One object per line
      .jsonFile(if (url.startsWith("http")) "file:///tmp/shakespeare_data.json" else url)
    shakespeare.printSchema() //null, line_id, line_number, play name, speaker, speech_number, text_entry

    val shakespeareRDD = shakespeare.rdd
      .filter(!_.isNullAt(1)) //filter erroneous rows
      .map( r => Oink( //create Oink object
        r.getLong(1).hashCode.toString, //random id
        r.getString(6).substring(0, Math.min(r.getString(6).length,140)), //max 140 characters
        Calendar.getInstance.getTime,
        r.getString(4).replaceAll("[^a-zA-Z ]","") //speaker name
      ))

    EsSpark.saveToEs(shakespeareRDD, "my_oinks/oink", Map("es.mapping.id" -> "id"))
  }
}
