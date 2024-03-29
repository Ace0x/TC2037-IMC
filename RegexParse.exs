#By Andrew Dunkerley and Juan Muniain
#Json Regex Parser

defmodule Regx do
  def get_lines(in_filename, out_filename) do
    expr =
      in_filename
      |> File.stream!()
      |> Enum.map(&token_from_line/1)
      |> Enum.filter(&(&1 != nil))
    tmp = "<!DOCTYPE html>\n<html>\n\t<head>\n\t\t<title>JSON Code</title>\n\t\t<link rel='stylesheet' href='../token_colors.css'>\n\t</head>\n\t<body>\n\t\t<h1>Date: #{DateTime.utc_now}</h1>\n\t\t<pre>\n#{expr}\n\t\t\t</pre>\n\t</body>\n</html>"
    expr = tmp
    File.write(out_filename, expr)
  end

  def token_from_line(line) do
    token_from_line(line,"",false,true)
  end

  def token_from_line(line, html_string, aftr,bftr) do
    #bftr checks for punctuations at the start of a line
    #aftr checks for expressions after ":"
    cond do

    #Checks for punctuations only at the start of a new line
    (Regex.match?(~r/\s*[{}\[\]\(\)]\s*"\N*"\s*:/,line)) and bftr ->
      [_string, token] = Regex.run(~r/(\s*[[:punct:]]\s*)/,line)
      [_h | t] = String.split(line, ~r/(\s*[[:punct:]]\s*)/, parts: 2)
      tmp = "#{html_string}<span class='punctuation'>#{token}</span>"
      html_string = tmp
      [tail] = t
      aftr = false
      token_from_line(tail,html_string,aftr,false)

    #Checks for expressions that include multiple " ": " " in the same line
    (Regex.match?(~r/\s*"[^"]*"\s*\:(\s*"[^"]*"\s*|\s*[^,]*\s*),\s*"[^"]*"\s*\:/,line)) ->
      [_string, token,token2,token3] = Regex.run(~r/(\s*"[^"]*"\s*)\:(\s*"[^"]*"\s*|\s*[^,]*\s*)(,)\s*"[^"]*"\s*\:/,line) # Matches object key name
      [_h | t] = String.split(line, ~r/(\s*"[^"]*"\s*\:(\s*"[^"]*"\s*|\s*[^,]*\s*),)/, parts: 2)
      itoken = getType(token2)
      tmp = "#{html_string}<span class='object-key'>#{token}</span><span class='dot'>:</span>#{itoken}<span class='punctuation'>#{token3}</span>"
      html_string = tmp
      [tail] = t
      aftr = true
      token_from_line(tail,html_string,aftr,false)

    #Checks for expressions that go before :
    (Regex.match?(~r/\s*"\N*"\s*\:/,line)) ->
      [_string, token] = Regex.run(~r/(\s*"\N*"\s*):/,line)
      [_h | t] = String.split(line, ~r/(\s*"\N*"\s*\:)/, parts: 2)
      tmp = "#{html_string}<span class='object-key'>#{token}</span><span class='dot'>:</span>"
      html_string = tmp
      [tail] = t
      aftr = true
      token_from_line(tail,html_string,aftr,false)

    #Checks for expressions that go after : but that have a punctuation beforehand
    (Regex.match?(~r/\s*[,\]\[{}]\s*"\N*"\s*/,line) and aftr) ->
      [_string, token] = Regex.run(~r/(\s*[,\]\[{}]\s*)/, line)
      [_h | t] = String.split(line, ~r/\s*[,\]\[{}]\s*/, parts: 2)
      tmp = "#{html_string}<span class='punctuation'>#{token}</span>"
      html_string = tmp
      [tail] = t
      aftr = false
      token_from_line(tail,html_string,aftr,false)

    #Checks for expresions that go after :
    (Regex.match?(~r/\s*"\N*"\s*/,line)) ->
      [_string, token] = Regex.run(~r/(\s*"\N*"\s*)/,line)
      [_h | t] = String.split(line, ~r/(\s*"\N*"\s*)/,  parts: 2 )
      tmp = "#{html_string}<span class='string'>#{token}</span>"
      html_string = tmp
      [tail] = t
      aftr = true
      token_from_line(tail,html_string,aftr,false)

    #Checks for expressions that have numbers after the : in any way
    (Regex.match?(~r/\s*\d+\.?\d*E?[+|-]?\d*\s*/,line)) ->
      [_string, token] = Regex.run(~r/(\s*\d+\.?\d*E?[+|-]?\d*\s*)/,line)
      [_h | t] = String.split(line, ~r/(\s*\d+\.?\d*E?[+|-]?\d*\s*)/,  parts: 2)
      tmp = "#{html_string}<span class='number'>#{token}</span>"
      html_string = tmp
      [tail] = t
      aftr = false
      token_from_line(tail,html_string,aftr,false)

    #Checks for expressions that include the keywords null true or false
    (Regex.match?(~r/\s*null|\s*true|\s*false\s*/,line)) ->
      [_string, token] = Regex.run(~r/(\s*null|\s*true|\s*false\s*)/,line)
      [_h | t] = String.split(line, ~r/(\s*null|\s*true|\s*false\s*)/, parts: 2)
      tmp = "#{html_string}<span class='boolean'>#{token}</span>"
      html_string = tmp
      [tail] = t
      aftr = false
      token_from_line(tail,html_string,aftr,false)

    #Checks for expressions that include a punctuation and are not at the start of a line
    (Regex.match?(~r/\s*[[:punct:]]\s*/,line)) ->
      [_string, token] = Regex.run(~r/(\s*[[:punct:]]\s*)/,line)
      [_h | t] = String.split(line, ~r/(\s*[[:punct:]]\s*)/, parts: 2)
      tmp = "#{html_string}<span class='punctuation'>#{token}</span>"
      html_string = tmp
      [tail] = t
      aftr = false
      token_from_line(tail,html_string,aftr,false)

    true ->
      html_string

    end
  end

  def getType(expr) do
    cond do
      (Regex.match?(~r/\s*"\N*"\s*/,expr)) ->
        [_string, token] = Regex.run(~r/(\s*"\N*"\s*)/,expr)
        tmp = "<span class='string'>#{token}</span>"
        tmp

      (Regex.match?(~r/\s*\d+\.?\d*E?[+|-]?\d*\s*/,expr)) ->
        [_string, token] = Regex.run(~r/(\s*\d+\.?\d*E?[+|-]?\d*\s*)/,expr)
        tmp = "<span class='number'>#{token}</span>"
        tmp

      (Regex.match?(~r/\s*null|\s*true|\s*false\s*/,expr)) ->
        [_string, token] = Regex.run(~r/(\s*null|\s*true|\s*false\s*)/,expr)
        tmp = "<span class='boolean'>#{token}</span>"
        tmp
    end
  end

  def multiParse do
    ["./Test_HW/out_file_000001",
    "./Test_HW/out_file_000002",
    "./Test_HW/out_file_000003",
    "./Test_HW/out_file_000004",
    "./Test_HW/out_file_000005",
    "./Test_HW/out_file_000006",
    "./Test_HW/out_file_000007",
    "./Test_HW/out_file_000008",
    "./Test_HW/out_file_000009",
    "./Test_HW/out_file_000010",
    "./Test_HW/out_file_000011",
    "./Test_HW/out_file_000012",
    "./Test_HW/out_file_000013",
    "./Test_HW/out_file_000014",
    "./Test_HW/out_file_000015",
    "./Test_HW/out_file_000016",
    "./Test_HW/out_file_000017",
    "./Test_HW/out_file_000018",
    "./Test_HW/out_file_000019",
    "./Test_HW/out_file_000020"]
    |> Enum.map(&Task.async(fn -> get_lines(&1 <> ".json",&1 <> ".html") end))
    |> Enum.map(&Task.await(&1))

  end

  def timer(function) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end

IO.puts(Regx.timer(fn -> Regx.multiParse() end))
