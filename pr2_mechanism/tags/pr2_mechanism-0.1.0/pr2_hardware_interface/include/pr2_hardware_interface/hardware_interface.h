/*********************************************************************
 * Software License Agreement (BSD License)
 *
 *  Copyright (c) 2008, Willow Garage, Inc.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above
 *     copyright notice, this list of conditions and the following
 *     disclaimer in the documentation and/or other materials provided
 *     with the distribution.
 *   * Neither the name of the Willow Garage nor the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *  POSSIBILITY OF SUCH DAMAGE.
 *********************************************************************/

#ifndef HARDWARE_INTERFACE_H
#define HARDWARE_INTERFACE_H

#include <string>
#include <vector>

#include <ros/ros.h>

namespace pr2_mechanism{

// See http://prdev.willowgarage.com/trac/personalrobots/ticket/883
template <class C>
void deleteElements(C *c)
{
  typename C::iterator it;
  for (it = c->begin(); it != c->end(); ++it)
  {
    if (*it != NULL)
    {
      delete (*it);
      *it = NULL;
    }
  }
}


class ActuatorState{
public:
  ActuatorState() :
      timestamp_(0),
      device_id_(0),
      encoder_count_(0),
      position_(0),
      encoder_velocity_(0),
      velocity_(0),
      calibration_reading_(0),
      calibration_rising_edge_valid_(0),
      calibration_falling_edge_valid_(0),
      last_calibration_rising_edge_(0),
      last_calibration_falling_edge_(0),
      is_enabled_(0),
      run_stop_hit_(0),
      last_requested_current_(0),
      last_commanded_current_(0),
      last_measured_current_(0),
      last_requested_effort_(0),
      last_commanded_effort_(0),
      last_measured_effort_(0),
      motor_voltage_(0),
      num_encoder_errors_(0),
      zero_offset_(0)
  {}
  double timestamp_;

  int device_id_;

  int encoder_count_;
  double position_;
  double encoder_velocity_;
  double velocity_;

  bool calibration_reading_;
  bool calibration_rising_edge_valid_;
  bool calibration_falling_edge_valid_;
  double last_calibration_rising_edge_;
  double last_calibration_falling_edge_;

  bool is_enabled_;
  bool run_stop_hit_;

  double last_requested_current_;
  double last_commanded_current_;
  double last_measured_current_;

  double last_requested_effort_;
  double last_commanded_effort_;
  double last_measured_effort_;

  double motor_voltage_;

  int num_encoder_errors_;
  int num_communication_errors_;

  // The difference between the actual reading from the encoder and the calibrated position of the actuator.  This field is write only; you should set it when calibrating the actuator, and then the actuator will take the zero offset into account when setting the position values.
  double zero_offset_;
};

class ActuatorCommand
{
public:
  ActuatorCommand() :
    enable_(0), effort_(0), digital_out_(false)
  {}
  bool enable_;
  double effort_;
  double current_;
  bool digital_out_;
};

class Actuator
{
public:
  Actuator() {}
  Actuator(const std::string &name) : name_(name) {}
  ~Actuator() {}

  std::string name_;
  ActuatorState state_;
  ActuatorCommand command_;
};

class HardwareInterface
{
public:
  HardwareInterface(int num_actuators)
  {
    for (int i = 0; i < num_actuators; ++i)
    {
      actuators_.push_back(new Actuator());
    }
  }
  ~HardwareInterface()
  {
    deleteElements(&actuators_);
  }
  std::vector<Actuator*> actuators_;
  ros::Time current_time_;
};
}

#endif
