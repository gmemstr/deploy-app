import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:preferences/preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'circleci-v1.dart' as circleciv1;
import 'circleci-v2.dart' as circleciv2;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefService.init();
  await FlutterDownloader.initialize();
  runApp(DeployApp());
}

Future<circleciv1.User> fetchUser() async {
  String apiKey = PrefService.get("api_key");
  final response = await http.get(
      "https://circleci.com/api/v1.1/me?circle-token=$apiKey",
      headers: {"Accept": "application/json"});

  if (response.statusCode == 200) {
    // If server returns an OK response, parse the JSON.
    return circleciv1.User.fromJson(json.decode(response.body));
  } else {
    // If that response was not OK, throw an error.
    throw Exception('Failed to load user');
  }
}

Future<List> fetchProjects() async {
  String apiKey = PrefService.get("api_key");
  List projects = [];
  final response = await http.get(
      "https://circleci.com/api/v1.1/projects?circle-token=$apiKey",
      headers: {"Accept": "application/json"});

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    for (int i = 0; i < jsonResponse.length; i++) {
      projects.add(circleciv1.Project.fromJson(jsonResponse[i]));
    }
    return projects;
  } else {
    throw Exception('Failed to load projects');
  }
}

Future<List> fetchProjectPipelines(String slug,
    {String nextPageToken = ""}) async {
  String apiKey = PrefService.get("api_key");
  List<circleciv2.Pipeline> pipelines = [];

  final response = await http.get(
      "https://circleci.com/api/v2/project/$slug/pipeline",
      headers: {"Accept": "application/json", "Circle-Token": apiKey});

  if (response.statusCode == 200) {
    pipelines = circleciv2.Pipeline.fromResponseJson(response.body);
  } else {
    throw Exception('Failed to load projects');
  }

  return pipelines;
}

Future<circleciv1.BuildDeep> fetchSingleBuild(String slug, int id) async {
  String apiKey = PrefService.get("api_key");

  final response = await http.get(
      "https://circleci.com/api/v1.1/project/$slug/$id?circle-token=$apiKey",
      headers: {"Accept": "application/json"});

  if (response.statusCode == 200) {
    return circleciv1.BuildDeep.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load projects');
  }
}

Future<String> getCommandLog(String url) async {
  final response = await http.get(url);

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    return jsonResponse[0]["message"];
  } else {
    throw Exception('Failed to load log');
  }
}

Future<int> runBuild(circleciv1.Project project) async {
  String slug = project.slug;
  String apiKey = PrefService.get("api_key");

  final response = await http.post(
      "https://circleci.com/api/v1.1/project/$slug?circle-token=$apiKey",
      headers: {"Accept": "application/json"});

  if (response.statusCode == 201) {
    var jsonResponse = json.decode(response.body);
    return jsonResponse["build_num"];
  } else {
    throw Exception('Failed to load log');
  }
}

Future<List> getArtifacts(
    circleciv1.Project project, circleciv1.BuildShallow build) async {
  String apiKey = PrefService.get("api_key");
  String slug = project.slug + "/" + build.num.toString();

  List<circleciv1.Artifact> artifacts = [];

  final response = await http.get(
      "https://circleci.com/api/v2/project/$slug/artifacts?circle-token=$apiKey",
      headers: {"Accept": "application/json"});

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    for (int i = 0; i < jsonResponse["items"].length; i++) {
      artifacts.add(circleciv1.Artifact.fromJson(jsonResponse["items"][i]));
    }
    return artifacts;
  } else {
    throw Exception('Failed to load artifacts');
  }
}

class DeployApp extends StatefulWidget {
  DeployApp({Key key}) : super(key: key);

  @override
  _DeployAppState createState() => _DeployAppState();
}

class _DeployAppState extends State<DeployApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch Data Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProjectList(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  Future<circleciv1.User> user;

  @override
  void initState() {
    super.initState();
    this.user = fetchUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.black,
      ),
      body: _buildSettingsPage(),
    );
  }

  _buildSettingsPage() {
    return FutureBuilder(
        future: this.user,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          List<Widget> basicPrefPage = [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: FlatButton(
                  padding: const EdgeInsets.all(15.0),
                  color: Colors.black,
                  textColor: Colors.white,
                  disabledColor: Colors.grey,
                  splashColor: Colors.blueAccent,
                  child: new Text(
                    'Get API Key',
                  ),
                  onPressed: () => launch('https://circleci.com/account/api')),
            ),
            TextFieldPreference(
              'API Key',
              'api_key',
            ),
            Divider(),
          ];
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData == true) {
            circleciv1.User user = snapshot.data;
            basicPrefPage.add(Center(
              child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: new Container(
                          width: 190.0,
                          height: 190.0,
                          decoration: new BoxDecoration(
                              shape: BoxShape.circle,
                              image: new DecorationImage(
                                  fit: BoxFit.fill,
                                  image: new NetworkImage(user.avatar)))),
                    ),
                    Text(
                      "Authenticated as " + user.login,
                      style: TextStyle(fontSize: 16),
                    ),
                  ]),
            ));
          }
          return PreferencePage(basicPrefPage);
        });
  }
}

class ProjectList extends StatefulWidget {
  @override
  ProjectListState createState() => ProjectListState();
}

class ProjectListState extends State<ProjectList> {
  final _biggerFont = const TextStyle(fontSize: 18.0);
  Future<List> projects;

  @override
  void initState() {
    super.initState();
    projects = fetchProjects();
  }

  Widget _buildProjects() {
    bool hasKey = (PrefService.get("api_key") != "" &&
        PrefService.get("api_key") != null);
    if (!hasKey) {
      return Scaffold(
        body: Center(
          child: Text(
            "Please set an API key under Settings",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.hasData == false ||
            (projectSnap.connectionState == ConnectionState.none &&
                projectSnap.hasData == null)) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return ListView.builder(
          itemCount: projectSnap.data.length,
          itemBuilder: (context, index) {
            circleciv1.Project project = projectSnap.data[index];
            List<Widget> list = [
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SingleProject(project)),
                  );
                },
                title: Text(
                  project.name,
                  style: _biggerFont,
                ),
                subtitle: Text(
                  project.url,
                ),
              ),
              Divider(),
            ];
            Column column = new Column(
              children: list,
            );
            return column;
          },
        );
      },
      future: fetchProjects(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('CircleCI Projects'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            icon: Icon(Icons.settings),
          )
        ],
      ),
      body: _buildProjects(),
    );
  }
}

class SingleProject extends StatefulWidget {
  final circleciv1.Project project;
  SingleProject(this.project);

  @override
  SingleProjectState createState() => SingleProjectState(this.project);
}

class SingleProjectState extends State<SingleProject> {
  final circleciv1.Project project;
  SingleProjectState(this.project);
  Future<List> builds;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildProject() {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.hasData == false ||
            (projectSnap.connectionState == ConnectionState.none &&
                projectSnap.hasData == null)) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return ListView.builder(
          itemCount: projectSnap.data.length,
          itemBuilder: (context, index) {
            circleciv2.Pipeline pipeline = projectSnap.data[index];

            List<Widget> list = [
              Card(
                  child: InkWell(
//                 onTap: () { Navigator.push(
//                  context,
//                  MaterialPageRoute(builder: (context) => SingleBuild(project, pipeline))),
//                 },
                child: Container(
                  child: ListTile(
                      title: Text(
                        "#" + pipeline.number.toString(),
                        style: TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Text(pipeline.vcs.commitSubject),
                      trailing: Column(children: [
                        Text(pipeline.trigger.actorLogin),
                        Text(pipeline.vcs.branchTag),
                      ])),
                ),
              )),
            ];
            return new Column(
              children: list,
            );
          },
        );
      },
      future: fetchProjectPipelines(project.slug),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(project.slug),
      ),
      body: new RefreshIndicator(
        child: _buildProject(),
        onRefresh: _handleRefresh,
      ),
      floatingActionButton: new Builder(builder: (BuildContext context) {
        return new FloatingActionButton(
            child: Icon(Icons.play_arrow),
            backgroundColor: Colors.black,
            onPressed: () async {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text("New build started"),
              ));
              int newBuildNum = await runBuild(project);
              setState(() {
                builds = fetchProjectPipelines(project.slug);
              });
            });
      }),
    );
  }

  // Refresh the state.
  Future<Null> _handleRefresh() async {
    setState(() {});
    await new Future.delayed(new Duration(seconds: 1));

    return null;
  }
}

class SingleBuild extends StatefulWidget {
  final circleciv1.Project project;
  final circleciv1.BuildShallow shallowBuild;
  SingleBuild(this.project, this.shallowBuild);

  @override
  SingleBuildState createState() => SingleBuildState(project, shallowBuild);
}

class SingleBuildState extends State<SingleBuild> {
  final circleciv1.Project project;
  final circleciv1.BuildShallow shallowBuild;

  SingleBuildState(this.project, this.shallowBuild);

  Future<circleciv1.BuildDeep> deepBuild;
  Future<List<circleciv1.Artifact>> artifacts;

  @override
  void initState() {
    super.initState();
    this.deepBuild = fetchSingleBuild(project.slug, shallowBuild.num);
  }

  Widget _buildBuild() {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.hasData == false ||
            (projectSnap.connectionState == ConnectionState.none &&
                projectSnap.hasData == null)) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        circleciv1.BuildDeep build = projectSnap.data;
        List<Widget> card = [
          ListTile(
            title: Text(build.commit,
                style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(build.triggeredBy),
            leading: Icon(
              Icons.label,
              color: Colors.grey,
            ),
          ),
          Divider(),
        ];

        // Build steps list.
        for (int i = 0; i < build.steps.length; i++) {
          circleciv1.BuildStep step = build.steps[i];
          Icon leadingIcon = Icon(Icons.check, color: hexToColor("#42C88A"));
          if (step.exitCode > 0 && step.exitCode < 10000) {
            leadingIcon = Icon(Icons.error, color: hexToColor("#ED5C5C"));
          }
          if (step.exitCode == 10000) {
            leadingIcon = Icon(Icons.info, color: Colors.grey);
          }
          card.add(ListTile(
            onTap: () {
              if (step.log == "no log found") {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text("No log found"),
                ));
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BuildLog(step)),
              );
            },
            title: Text(step.name),
            leading: leadingIcon,
          ));
        }
        return Scaffold(
          body: Center(
              child: ListView(
            children: card,
          )),
        );
      },
      future: this.deepBuild,
    );
  }

  Widget _buildArtifactList() {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.hasData == false ||
            (projectSnap.connectionState == ConnectionState.none &&
                projectSnap.hasData == null)) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        List artifacts = projectSnap.data;
        List<Widget> card = [
          ListTile(
            title: Text("Artifacts",
                style: TextStyle(fontWeight: FontWeight.w500)),
            leading: Icon(
              Icons.cloud_download,
              color: Colors.grey,
            ),
          ),
          Divider(),
        ];

        // Build steps list.
        for (int i = 0; i < artifacts.length; i++) {
          circleciv1.Artifact artifact = artifacts[i];
          card.add(ListTile(
            onTap: () async {
              Directory dir = await getTemporaryDirectory();
              await FlutterDownloader.enqueue(
                url: artifact.url,
                savedDir: dir.path,
                showNotification: true,
                openFileFromNotification: true,
              );
            },
            title: Text(artifact.path),
          ));
        }
        return Scaffold(
          body: Center(
              child: ListView(
            children: card,
          )),
        );
      },
      future: getArtifacts(project, shallowBuild),
    );
  }

  Widget _buildConfigViewer() {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.hasData == false ||
            (projectSnap.connectionState == ConnectionState.none &&
                projectSnap.hasData == null)) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        circleciv1.BuildDeep build = projectSnap.data;
        String config = build.configuration;

        Widget body = Text(
          config,
          style: TextStyle(fontFamily: "monospace", color: Colors.white),
        );
        return Scaffold(
            backgroundColor: Colors.black,
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: body,
              ),
            ));
      },
      future: this.deepBuild,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(project.slug + "/" + shallowBuild.num.toString()),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.description)),
              Tab(icon: Icon(Icons.cloud_download)),
              Tab(icon: Icon(Icons.code)),
            ],
          ),
        ),
        body: TabBarView(children: [
          new RefreshIndicator(
            child: _buildBuild(),
            onRefresh: _handleRefresh,
          ),
          _buildArtifactList(),
          _buildConfigViewer(),
        ]),
      ),
      length: 3,
    );
  }

  // Refresh the state.
  Future<Null> _handleRefresh() async {
    setState(() {});
    await new Future.delayed(new Duration(seconds: 1));

    return null;
  }
}

class BuildLog extends StatefulWidget {
  final circleciv1.BuildStep step;
  BuildLog(this.step);

  @override
  BuildLogState createState() => BuildLogState(this.step);
}

class BuildLogState extends State<BuildLog> {
  final circleciv1.BuildStep step;
  BuildLogState(this.step);
  Future<String> log;

  @override
  void initState() {
    super.initState();
    log = getCommandLog(this.step.log);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(step.name),
      ),
      body: _buildLog(),
    );
  }

  Widget _buildLog() {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.hasData == false ||
            (projectSnap.connectionState == ConnectionState.none &&
                projectSnap.hasData == null)) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        String log = projectSnap.data;
        return Scaffold(
          backgroundColor: Colors.black87,
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Text(
                log,
                style: TextStyle(fontFamily: "monospace", color: Colors.white),
              ),
            ),
          ),
        );
      },
      future: getCommandLog(step.log),
    );
  }
}

Color hexToColor(String code) {
  return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}
