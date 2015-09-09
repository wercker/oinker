package com.test

// import com.datastax.spark.connector._
import org.apache.spark.{SparkContext, SparkConf}
import scala.collection.immutable.HashSet
import org.elasticsearch.spark._
import org.elasticsearch.spark.rdd.EsSpark

case class Frequency(kind: String, key: String, frequency: Int)

object SparkElasticsearchTest {
  //A stoplist is a list of connector words that are analytically unimportant
  val stoplist = new HashSet[String]() ++ ("a,able,about,across,after,all,almost,also,am,among,an,and,any,are,as,at," +
    "be,because,been,but,by,can,cannot,could,dear,did,do,does,either,else,ever,every,for,from,get,got,had,has,hath," +
    "have,he,her,hers,him,his,how,however,i,if,in,into,is,it,its,just,least,let,like,likely,may,me,might,more,most," +
    "must,my,neither,no,nor,not,of,off,often,on,only,or,other,our,own,rather,said,say,says,shall,she,should,since," +
    "so,some,than,that,the,thee,their,them,then,there,these,they,this,thou,thy,tis,to,too,twas,upon,us,wants,was,we," +
    "well,were,what,when,where,which,while,who,whom,why,will,with,would,yet,you,your").split(",")

  def main(args: Array[String]) {
    //create a spark configuration to connect to elasticsearch
    val conf = new SparkConf(true)
      .set("es.nodes", args.lift(0).getOrElse("localhost"))
      .set("es.index.auto.create", "true")
    //setup a spark job and create an RDD from a elasticsearch table
    val rdd = new SparkContext("local", "Oinker Analytics", conf).esRDD("my_oinks/oink")
    //turn every 'oink' into a series of words
    val words = rdd.flatMap( o =>
      o._2("content") //using the 'content' field
        .toString
        .replaceAll("[^a-zA-Z ]", "") //only letters and spaces
        .toLowerCase
        .split(" ")) //splitting on spaces
    val freqs = words
        .map(w => (w, 1)) //identity
        .reduceByKey(_ + _) //adding frequency
        .filter(t => t._1 != "" && !stoplist.contains(t._1)) //remove items in stoplist
        .map(t => new Frequency("oink", t._1, t._2))

    EsSpark.saveToEs(freqs, "analytics/freq")
  }
}
