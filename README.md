# Real-time Image Classifier, Trends Analyzer, and Dataset Creator

This is the project realized for the exam of the subject "Sistemi Cloud e IoT" (University of Catania, Computer Science Department).

# Architecture

<img src='cloud_project_architecture.png'>

The application above will run on a 3 Azure VMs cluster, in a user-created Kubernetes cluster of 3 nodes (1 master, 2 workers).

# Disclaimer

<b><h3>This product uses the Flickr API but is not endorsed or certified by SmugMug, Inc.</h3></b>
<h4>I'm not responsible for misuse of this project.</h4>
I also strongly recommend to read the Flickr APIs Terms of Use in order to be aware of what is possible to do and what is not possible to do with Flickr APIs and the data collected through them.

# How to start this project?

1. Install Azure CLI and do login.
2. Set FLICKR_API_KEY and FLICKR_API_SECRET env variables value in config.sh file.
3. Run './create_cluster_and_deploy_project.sh' command in main folder.
4. Enjoy!

<b>If you want to customize clusters settings, edit </b>azure_cluster_management/cluster_config.sh<b> and </b>config.sh<b> files</b>.
  
# How to query Dataset Creator microservice?

You can use the following url template:  

http://\<master-host-public-ip\>:8081/getDataset?class=\<class-id\>&max=\<max-urls-to-retrieve\>&min_conf=\<min-confidence-score-the-assigned-class-must-have-to-add-url-in-output-list\>

To get the full list of available class ids visit:

http://\<master-host-public-ip\>:8081/getClasses<br>
  
<h4>N.B.</h4>
- Confidence score is a decimal number in [0.0, 1.0].

  - Setting it to a negative number would cause images with whatever class confidence score to be included in the output list.  
  - Setting it to a number greater than 1.0 would lead to an empty output list.

# How to access Kibana GUI?
  
Simply visit:

http://\<master-host-public-ip\>:5601
