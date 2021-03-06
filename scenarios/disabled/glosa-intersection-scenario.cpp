#include "ns3/core-module.h"
#include "ns3/mobility-module.h"
#include "ns3/ns2-mobility-helper.h"
#include "ns3/internet-module.h"
#include "ns3/wifi-module.h"
#include "ns3/applications-module.h"
#include "ns3/network-module.h"
#include "ns3/wifi-helper.h"
#include "ns3/rng-seed-manager.h"

// 802.11p specific packages
#include "ns3/ocb-wifi-mac.h"
#include "ns3/wifi-80211p-helper.h"
#include "ns3/wave-mac-helper.h"

// NDN packages
#include "ns3/ndnSIM-module.h"
#include "helper/ndn-fib-helper.hpp"

using namespace std;
namespace ns3 {

NS_LOG_COMPONENT_DEFINE ("GlosaIntersectionScenario");

int main (int argc, char *argv[])
{
  // Setup member variables
  std::string traceFile;
  std::string disseminationMethod;
  int nodeNum;
  double simulationDuration;
  std::string phyMode ("OfdmRate6MbpsBW10MHz");
  std::string range = "100"; // desired transmission range for the signal
  std::string payloadSize = "600";
  bool verbose = false;
  bool network = true;
  double producerInterval = 1; // frequency between producer data pushes
  double consumerInterval = 1; // frequency between consumer interests generation

  // Parse command line attribute
  CommandLine cmd;
  cmd.AddValue ("traceFile", "Ns2 movement trace file", traceFile);
  cmd.AddValue ("nodeNum", "Number of nodes in the trace file", nodeNum);
  cmd.AddValue ("duration", "Duration of Simulation", simulationDuration);
  cmd.AddValue ("disseminationMethod", "The method of information dissemination: 'pure-ndn', 'unsolicited', or 'proactive'", disseminationMethod);
  cmd.AddValue ("verbose", "turn on all WifiNetDevice log components", verbose);
  cmd.AddValue ("network", "install the ndn stack on all nodes", network);
  cmd.AddValue ("range", "The maximm range for transmission, can be 100, 200 or 300 metres", range);
  cmd.Parse (argc,argv);

  // Check command line arguments
  if (traceFile.empty () || nodeNum <= 0 || simulationDuration <= 0)
  {
    std::cout << "Make sure to pass all required arguments traceFile, nodeNum, duration, and disseminationMethod";
    return 0;
  }

  // Logging setup
  if (verbose) {
    LogComponentEnable ("Ns2MobilityHelper", LOG_LEVEL_DEBUG);
    LogComponentEnable ("GlosaIntersectionScenario", LOG_LEVEL_DEBUG);
    LogComponentEnable ("ndn.ModConsumerCbr", LOG_LEVEL_DEBUG);
    LogComponentEnable ("ndn.ModConsumer", LOG_LEVEL_DEBUG);
    LogComponentEnable ("ndn.ProactiveProducer", LOG_LEVEL_DEBUG);
  }

  // Create consumer and producer nodes
  NodeContainer consumerNodes;
  consumerNodes.Create(nodeNum);
  NodeContainer producerNodes;
  producerNodes.Create(1);

  // Nodes for testing purposes
  // NodeContainer consumerNodes;
  // consumerNodes.Create(1);
  // NodeContainer producerNodes;
  // producerNodes.Create(1);
  
  // Mobility for vehicles comes from traceFile
  Ns2MobilityHelper ns2 = Ns2MobilityHelper (traceFile);
  ns2.Install ();

  // Good for testing
  // MobilityHelper testNodeMobility;
  // Ptr<ListPositionAllocator> testPosAlloc = CreateObject<ListPositionAllocator> ();
  // testPosAlloc->Add(Vector (510.0, 405.0, 0.0));
  // testNodeMobility.SetPositionAllocator (testPosAlloc);
  // testNodeMobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  // testNodeMobility.Install(consumerNodes);

  // Mobility of traffic light is a fixed position ~intersection of nodes
  MobilityHelper trafficLightMobility;
  Ptr<ListPositionAllocator> posAlloc = CreateObject<ListPositionAllocator> ();
  posAlloc->Add(Vector (500.0, 405.0, 0.0));
  trafficLightMobility.SetPositionAllocator (posAlloc);
  trafficLightMobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  trafficLightMobility.Install(producerNodes);

  // This is to ensure deterministic results from distributions
  ns3::RngSeedManager::SetSeed (3);

  if (network) {

    //determining transmission range: 100m = 3.0, 200m = 2.72, 300m = 2.55
    double range_d = 3.0;
    
    NS_LOG_DEBUG("range=" << range);
    if (range == "200") {
      range_d = 2.72;
    } else if (range == "300") {
      range_d = 2.55;
    }

    // The below set of helpers put together the required Wi-Fi Network Interface Controllers (NICs)
    YansWifiChannelHelper wifiChannel;
    wifiChannel.SetPropagationDelay("ns3::ConstantSpeedPropagationDelayModel");
    wifiChannel.AddPropagationLoss("ns3::LogDistancePropagationLossModel", "Exponent", DoubleValue(range_d));

    YansWifiPhyHelper wifiPhy =  YansWifiPhyHelper::Default ();
    wifiPhy.SetPcapDataLinkType (WifiPhyHelper::DLT_IEEE802_11);
    wifiPhy.SetChannel (wifiChannel.Create ());

    NqosWaveMacHelper wifi80211pMac = NqosWaveMacHelper::Default ();
    Wifi80211pHelper wifi80211p = Wifi80211pHelper::Default ();
    
    if (verbose) {
      wifi80211p.EnableLogComponents ();
    }

    wifi80211p.SetRemoteStationManager ("ns3::ConstantRateWifiManager",
                                        "DataMode",StringValue (phyMode),
                                        "ControlMode",StringValue (phyMode));

    NetDeviceContainer vehicularDevices = wifi80211p.Install(wifiPhy, wifi80211pMac, consumerNodes);
    NetDeviceContainer trafficLightDevices = wifi80211p.Install(wifiPhy, wifi80211pMac, producerNodes);

    ns3::PacketMetadata::Enable ();

    ndn::StackHelper ndnHelper;
    ndnHelper.SetDefaultRoutes(true);
    ndnHelper.setCsSize(100);
    ndnHelper.setPolicy("nfd::cs::lru");
    // ndnHelper.SetOldContentStore("ns3::ndn::cs::Freshness::Lru","MaxSize", "1000");
    ndnHelper.Install(consumerNodes);

    // ndnHelper.SetOldContentStore("ns3::ndn::cs::Nocache");
    ndnHelper.Install(producerNodes);

    ndn::StrategyChoiceHelper::InstallAll("/", "/localhost/nfd/strategy/best-route");
    ndn::AppHelper consumerHelper("ModConsumerCbr");

    // This is a hack to get the simulation to run properly. Otherwise interests never satisfy from cache -> NDN Bug
    // consumerHelper.SetPrefix("/test/dummy");
    // consumerHelper.SetAttribute("Frequency", DoubleValue(101));
    // consumerHelper.Install(consumerNodes);

    // Simulating requests for CAM packets
    consumerHelper.SetPrefix("/test/cam");
    consumerHelper.SetAttribute("Frequency", DoubleValue(consumerInterval));
    consumerHelper.SetAttribute("LifeTime", TimeValue(Seconds(consumerInterval)));
    consumerHelper.SetAttribute("Randomize", StringValue("uniform"));
    consumerHelper.Install(consumerNodes);

    NS_LOG_DEBUG("disseminationMethod=" << disseminationMethod);
    if (disseminationMethod == "pure-ndn" || disseminationMethod == "unsolicited")
    {
      NS_LOG_DEBUG("producer is pure ndn");
      // The producer should be satisfying requests for CAM packets
      ndn::AppHelper producerHelper("ns3::ndn::Producer");
      producerHelper.SetPrefix("/test/cam");
      producerHelper.SetAttribute("PayloadSize", StringValue(payloadSize));
      producerHelper.SetAttribute("Freshness", TimeValue (Seconds(producerInterval)));
      producerHelper.Install(producerNodes);
    } else {  // proactive
      NS_LOG_DEBUG("producer is proactive");
      // The producer should be satisfying requests for CAM packets
      ndn::AppHelper producerHelper("ns3::ndn::ProactiveProducer");
      producerHelper.SetPrefix("/test/cam");
      producerHelper.SetAttribute("PayloadSize", StringValue(payloadSize));
      producerHelper.SetAttribute("Freshness", TimeValue (Seconds(producerInterval)));
      producerHelper.SetAttribute("Frequency", DoubleValue(producerInterval));
      producerHelper.Install(producerNodes);
    }
  }

  Simulator::Stop (Seconds (100.0));

  if (network) {
    ndn::L3RateTracer::InstallAll("./graphs/data/rate-trace.txt", Seconds(1));
    ndn::AppDelayTracer::InstallAll("./graphs/data/app-delays-trace.txt");
  }

  Simulator::Run ();
  Simulator::Destroy ();

  return 0;
}

} //namespace ns3

int
main(int argc, char* argv[])
{
  return ns3::main(argc, argv);
}