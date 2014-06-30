# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# See #LOC

# = Name Server Record (LOC)
#
# In the Domain Name System, a LOC record (RFC 1876) is a means for expressing
# geographic location information for a domain name.
# It contains WGS84 Latitude, Longitude and Altitude information together with
# host/subnet physical size and location accuracy. This information can be
# queried by other computers connected to the Internet.
#
# Obtained from http://en.wikipedia.org/wiki/LOC_record
#
class LOC < Record
end
